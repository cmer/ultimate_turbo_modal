# The Ultimate Turbo Modal for Rails (UTMR)

There are MANY Turbo/Hotwire/Stimulus modal dialog implementations out there, and it seems like everyone goes about it a different way. However, as you may have learned the hard way, the majority fall short in different, often subtle ways. They generally cover the basics quite well, but do not check all the boxes for real-world use.

UTMR aims to be the be-all and end-all of Turbo Modals. I believe it is the best (only?) full-featured implementation and checks all the boxes. It is feature-rich, yet extremely easy to use.

Under the hood, it uses [Stimulus](https://stimulus.hotwired.dev), [Turbo](https://turbo.hotwired.dev/), [el-transition](https://github.com/mmccall10/el-transition), and [Idiomorph](https://github.com/bigskysoftware/idiomorph).

It currently ships in a three flavors: Tailwind v3, Tailwind v4 and regular, vanilla CSS. It is easy to create your own variant to suit your needs.

## Installation

```
$ bundle add ultimate_turbo_modal
$ bundle exec rails g ultimate_turbo_modal:install
```

## Usage

1. Wrap your view inside a `modal` block as follow:

```erb
<%= modal do %>
  Hello World!
<% end %>
```

2. Link to your view by specifying `modal` as the target Turbo Frame:

```erb
<%= link_to "Open Modal", "/hello_world", data: { turbo_frame: "modal" } %>
```

Clicking on the link will automatically open the content of the view inside a modal. If you open the link in a new tab, it will render normally outside of the modal. Nothing to do!

This is really all you should need to do for most use cases.

### Setting Title and Footer

You can set a custom title and footer by passing a block. For example:

```erb
<%= modal do |m| %>
  <% m.title do %>
    <div>My Title</div>
  <% end %>

  <p>Your modal body</p>
  <%= form_with url: "#", html: { id: "myform" } do |f| %>
    <p>..</p>
  <% end %>

  <% m.footer do %>
    <input type="submit" form="myform">Submit</input>
  <% end %>
<% end %>
```

You can also set a title with options (see below).

### Detecting modal at render time

If you need to do something a little bit more advanced when the view is shown outside of a modal, you can use the `#inside_modal?` method as such:

```erb
<% if inside_modal? %>
  <h1 class="text-2xl mb-8">Hello from modal</h1>
<% else %>
  <h1 class="text-2xl mb-8">Hello from a normal page render</h1>
<% end %>
```



&nbsp;
&nbsp;
## Options

Do not get overwhelmed with all the options. The defaults are sensible.

| name | default value | description |
|------|---------------|-------------|
| `advance` | `true` | When opening the modal, the URL in the URL bar will change to the URL of the view being shown in the modal. The Back button dismisses the modal and navigates back. If a URL is specified as a string (e.g. `advance: "/other-path"), the browser history will advance, and the URL shown in the URL bar will be replaced with the value specified. |
| `close_button` | `true` | Shows or hide a close button (X) at the top right of the modal. |
| `header` | `true` | Whether to display a modal header. |
| `header_divider` | `true` | Whether to display a divider below the header. |
| `padding` | `true` | Adds padding inside the modal. |
| `redirect_behavior` | `"smooth"` | Controls how form submission redirects are handled. Set to `"smooth"` to enable enhanced redirect behavior where same-page redirects morph content behind the modal, and different-page redirects close the modal smoothly before navigating. Set to `"immediate"` for the original, more abrupt redirect behavior that did not close the modal before redirecting. |
| `title` | `nil` | Title to display in the modal header. Alternatively, you can set the title with a block. |

### Example usage with options

```erb
<%= modal(padding: true, close_button: false, advance: false) do %>
  Hello World!
<% end %>
```

```erb
<%= modal(padding: true, close_button: false, advance: "/foo/bar") do %>
  Hello World!
<% end %>
```

### Redirect Behavior

This is a slightly more advanced topic. You likely will not need to worry about this, or change the default settings.

When `redirect_behavior: "smooth"` is enabled (which is the default), the modal provides enhanced handling of form submission redirects and frame-breaking links:

- **Same-page redirects**: The page content behind the modal is updated via morphing, then the modal closes smoothly
- **Different-page redirects**: The modal closes with animation, then navigates to the destination page
- **Frame-breaking links**: Links without `data: { turbo_frame: "modal" }` close the modal smoothly before navigating

```erb
<%= modal(redirect_behavior: "smooth") do %>
  <%= form_with model: @post do |f| %>
    <!-- Form fields -->
    <%= f.submit "Save" %>
  <% end %>
<% end %>
```

#### Forcing Full Navigation

For pages that require full navigation (different CSS frameworks, external apps, etc.), add `data-modal-force-visit` to the body tag:

```erb
<!-- In a layout file -->
<body data-modal-force-visit>
  <!-- This page will trigger full navigation instead of smooth morphing -->
</body>
```

## Features and capabilities

- Extremely easy to use
- Fully responsive
- Does not break if a user navigates directly to a page that is usually shown in a modal
- Opening a modal in a new browser tab (ie: right click) gracefully degrades without having to code a modal and non-modal version of the same page
- Automatically handles URL history (ie: pushState) for shareable URLs
- pushState URL optionally overrideable
- Seamless support for multi-page navigation within the modal
- Seamless support for forms with validations
- Seamless support for Rails flash messages
- Enter/leave animation (fade in/out)
- Support for long, scrollable modals
- Properly locks the background page when scrolling a long modal
- Click outside the modal to dismiss
- Option to whitelist CSS selectors that won't dismiss the modal when clicked outside the modal (ie: datepicker)
- Keyboard control; ESC to dismiss
- Automatic (or not) close button


## Demo

A demo application can be found at https://github.com/cmer/ultimate_turbo_modal-demo. A video demo can be seen here: [https://youtu.be/BVRDXLN1I78](https://youtu.be/BVRDXLN1I78).

## Upgrading from 1.x

Please see the [Upgrading Guide](UPGRADING.md) for detailed instructions on how to upgrade from version 1.x.

## Thanks

Thanks to [@joeldrapper](https://github.com/joeldrapper) and [@konnorrogers](https://github.com/KonnorRogers) for all the help!


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cmer/ultimate_turbo_modal.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
