## default forms to being remote

We disabled remote forms when using `form_with` because things like flash
messages don't show up when we re-render. Maybe we can come up with a way of
adding a `layout/application.js.haml` to insert flashes into the page
dynamically. Search for the configuration:

```rb
Rails.application.config.action_view.form_with_generates_remote_forms = false
```
