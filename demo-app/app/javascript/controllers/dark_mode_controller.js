import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"];

  toggleTheme() {
    // Toggle the dark class on the html element
    if (document.documentElement.classList.contains('dark')) {
      document.documentElement.classList.remove('dark');
      this.setCookie('theme', 'light');
    } else {
      document.documentElement.classList.add('dark');
      this.setCookie('theme', 'dark');
    }
  }

  setCookie(name, value, days = 7) {
    const expires = new Date(Date.now() + days * 864e5).toUTCString();
    document.cookie = `${name}=${value};expires=${expires};path=/`;
  }

  getCookie(name) {
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) return parts.pop().split(';').shift();
    return null;
  }
}
