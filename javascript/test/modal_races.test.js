import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, afterEach, before, beforeEach, test } from 'node:test';
import { chromium } from 'playwright';

const sources = {
  '/': 'test/fixtures/modal.html',
  '/stimulus.js': 'node_modules/@hotwired/stimulus/dist/stimulus.js',
  '/turbo.js': 'node_modules/@hotwired/turbo/dist/turbo.es2017-esm.js',
  '/utm.js': 'dist/ultimate_turbo_modal.js'
};
let browser;
let page;
let errors;

before(async () => { browser = await chromium.launch(); });
after(async () => { await browser?.close(); });
beforeEach(async () => {
  page = await browser.newPage();
  errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.route('http://utm.test/**', async route => {
    const pathname = new URL(route.request().url()).pathname;
    const source = sources[pathname];
    if (!source) return route.fulfill({ status: 404, body: 'Not found' });
    await route.fulfill({
      contentType: pathname.endsWith('.js') ? 'text/javascript' : 'text/html',
      body: await readFile(new URL(`../${source}`, import.meta.url))
    });
  });
  await page.goto('http://utm.test/');
  await page.waitForFunction(() => window.ready);
  await page.evaluate(() => {
    document.getElementById('modal').innerHTML = dialogHTML();
    window.closedEvents = 0;
    window.historyBackCalls = 0;
    history.back = () => window.historyBackCalls++;
    document.getElementById('modal').addEventListener('modal:closed', () => window.closedEvents++);
  });
  await page.waitForFunction(() => window.modal?.containerTarget.hasAttribute('data-entered'));
});
afterEach(async () => {
  await page?.close();
  assert.deepEqual(errors, [], 'browser errors');
});

test('outer-frame morph preserves the live dialog and controller-owned attributes', async () => {
  const result = await page.evaluate(async () => {
    const dialog = window.modal.containerTarget;
    dialog.dataset.utmrHistoryAdvanced = 'true';
    dialog.dataset.utmrSkipHistoryBack = 'true';
    await prepareMorph(dialogHTML('Updated'))();
    return {
      sameNode: dialog === document.querySelector('dialog'),
      open: dialog.open,
      entered: dialog.hasAttribute('data-entered'),
      history: dialog.dataset.utmrHistoryAdvanced,
      skip: dialog.dataset.utmrSkipHistoryBack,
      text: dialog.textContent
    };
  });
  assert.deepEqual(result, { sameNode: true, open: true, entered: true, history: 'true', skip: 'true', text: 'Updated' });
});

test('superseded close settles waiters without firing modal:closed or consuming history', async () => {
  const result = await page.evaluate(async () => {
    document.body.dataset.turboModalHistoryAdvanced = 'true';
    const controller = window.modal;
    const promise = controller.hideModalWithPromise();
    await prepareMorph(dialogHTML('Replacement'))();
    const closedAtRevival = window.closedEvents;
    await promise;
    await new Promise(resolve => setTimeout(resolve, 450));
    return {
      closedAtRevival, closed: window.closedEvents,
      open: controller.containerTarget.open, hiding: controller.hidingModal,
      token: controller.turboFrame.dataset.utmrCloseToken ?? null,
      historyBack: window.historyBackCalls,
      historyAdvanced: document.body.dataset.turboModalHistoryAdvanced
    };
  });
  // The dialog is on screen with newer content, so the close was cancelled,
  // not completed: hideModalWithPromise resolves but modal:closed never fires.
  assert.deepEqual(result, { closedAtRevival: 0, closed: 0, open: true, hiding: false, token: null, historyBack: 0, historyAdvanced: 'true' });
  await page.evaluate(() => window.modal.hideModal());
  await page.waitForFunction(() => !document.querySelector('dialog'));
  assert.equal(await page.evaluate(() => window.closedEvents), 1);
  assert.equal(await page.evaluate(() => window.historyBackCalls), 1);
});

test('close beginning after before-frame-render revives at actual render time', async () => {
  const result = await page.evaluate(async () => {
    const render = prepareMorph(dialogHTML('Late replacement'));
    const controller = window.modal;
    controller.hideModal();
    await render();
    await new Promise(resolve => setTimeout(resolve, 450));
    return { open: controller.containerTarget.open, entered: controller.containerTarget.hasAttribute('data-entered'), hiding: controller.hidingModal };
  });
  assert.deepEqual(result, { open: true, entered: true, hiding: false });
});

test('a replacement request survives the old close deadline without reopening the dismissed modal', async () => {
  await page.route('http://utm.test/slow', async route => {
    await new Promise(resolve => setTimeout(resolve, 600));
    await route.fulfill({
      contentType: 'text/html',
      body: '<turbo-frame id="modal"><dialog id="modal-container" class="utmr" data-controller="modal" data-modal-target="container"><div id="modal-inner" data-modal-target="content">Slow replacement</div></dialog></turbo-frame>'
    });
  });
  const midRequest = await page.evaluate(async () => {
    window.modal.hideModal();
    Turbo.visit('/slow', { frame: 'modal' });
    // Past the close deadline, still short of the response.
    await new Promise(resolve => setTimeout(resolve, 450));
    return { onScreen: !!document.querySelector('dialog[open]'), closed: window.closedEvents };
  });
  // The user dismissed it, so it stays dismissed while the replacement loads.
  assert.deepEqual(midRequest, { onScreen: false, closed: 1 });
  await page.waitForFunction(() => document.querySelector('dialog[open]')?.textContent === 'Slow replacement', null, { timeout: 3000 });
  assert.equal(await page.locator('#modal').getAttribute('src'), 'http://utm.test/slow');
  assert.equal(await page.evaluate(() => window.closedEvents), 1);
});

test('morph removing the closing dialog does not revive a detached controller', async () => {
  await page.evaluate(async () => {
    window.modal.hideModal();
    await prepareMorph('<p>No modal</p>')();
  });
  await page.waitForFunction(() => !window.modal);
  assert.equal(await page.locator('dialog').count(), 0);
});

test('promise fallback settles after controller removal cancels cleanup', async () => {
  const result = await page.evaluate(async () => {
    const controller = window.modal;
    const promise = controller.hideModalWithPromise();
    controller.containerTarget.remove();
    await promise;
    return true;
  });
  assert.equal(result, true);
});

test('hover prefetch does not supersede an advanced modal close', async () => {
  await page.route('http://utm.test/prefetched', route => route.fulfill({ contentType: 'text/html', body: '<turbo-frame id="modal"></turbo-frame>' }));
  await page.evaluate(() => {
    document.body.dataset.turboModalHistoryAdvanced = 'true';
    const link = document.createElement('a');
    link.href = '/prefetched';
    link.dataset.turboFrame = 'modal';
    link.textContent = 'Prefetch';
    document.body.append(link);
    window.modal.hideModal();
    link.dispatchEvent(new MouseEvent('mouseenter'));
  });
  await page.waitForRequest(request => request.headers()['x-sec-purpose'] === 'prefetch');
  await page.waitForFunction(() => !document.querySelector('dialog'));
  assert.equal(await page.evaluate(() => window.historyBackCalls), 1);
});

test('failed replacement leaves the dismissed modal closed and its history entry unspent', async () => {
  await page.route('http://utm.test/failed', async route => {
    await new Promise(resolve => setTimeout(resolve, 600));
    await route.abort('failed');
  });
  const failedRequest = page.waitForEvent('requestfailed', request => request.url() === 'http://utm.test/failed');
  await page.evaluate(() => {
    document.body.dataset.turboModalHistoryAdvanced = 'true';
    window.modal.hideModal();
    Turbo.visit('/failed', { frame: 'modal' });
  });
  await failedRequest;
  await page.waitForFunction(() => !document.getElementById('modal').hasAttribute('busy'));
  // Dismissing it meant dismissing it, so a replacement that never arrives
  // leaves nothing behind.
  assert.equal(await page.locator('dialog').count(), 0);
  assert.equal(await page.evaluate(() => window.modal), undefined);
  assert.equal(await page.evaluate(() => window.closedEvents), 1);
  // The frame had already moved on, so the close left the history entry for a
  // replacement to inherit. The next advanced modal reuses it instead of
  // pushing a second one, keeping the entry count balanced.
  assert.equal(await page.evaluate(() => window.historyBackCalls), 0);
  assert.equal(await page.evaluate(() => document.body.dataset.turboModalHistoryAdvanced), 'true');
  // Turbo propagates the deliberately failed fetch as an unhandled rejection.
  errors = errors.filter(message => message !== 'Failed to fetch');
});

test('reconnecting a closing dialog retains its original token without claiming the frame', async () => {
  const result = await page.evaluate(async () => {
    const controller = window.modal;
    const dialog = controller.containerTarget;
    const frame = controller.turboFrame;
    controller.hideModal();
    const originalToken = dialog.dataset.utmrCloseToken;
    dialog.remove();
    await new Promise(resolve => setTimeout(resolve, 0));
    frame.dataset.utmrCloseToken = 'new-owner';
    frame.append(dialog);
    await new Promise(resolve => setTimeout(resolve, 100));
    return { originalToken, dialogToken: dialog.dataset.utmrCloseToken, frameToken: frame.dataset.utmrCloseToken };
  });
  assert.equal(result.dialogToken, result.originalToken);
  assert.equal(result.frameToken, 'new-owner');
  await page.waitForFunction(() => !document.querySelector('dialog'));
  assert.equal(await page.evaluate(() => document.getElementById('modal').dataset.utmrCloseToken), 'new-owner');
});

test('morph during reconnect supersedes the close before its animation resumes', async () => {
  const result = await page.evaluate(async () => {
    const controller = window.modal;
    const dialog = controller.containerTarget;
    const frame = controller.turboFrame;
    controller.hideModal();
    dialog.remove();
    await Promise.resolve();
    frame.append(dialog);
    await Promise.resolve();
    const resuming = controller.hidingModal && !dialog.hasAttribute('data-closing');
    await prepareMorph(dialogHTML('Replacement during reconnect'))();
    await new Promise(resolve => setTimeout(resolve, 450));
    return { resuming, connected: dialog.isConnected, open: dialog.open, entered: dialog.hasAttribute('data-entered'), hiding: controller.hidingModal, closed: window.closedEvents };
  });
  assert.deepEqual(result, { resuming: true, connected: true, open: true, entered: true, hiding: false, closed: 0 });
});
