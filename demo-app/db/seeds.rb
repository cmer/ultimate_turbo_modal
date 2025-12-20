# Clear existing posts
Post.destroy_all

# Create 5 sample posts
posts = [
  {
    title: "Getting Started with Turbo",
    body: "Turbo accelerates links and form submissions by negating the need for full page reloads.",
    publish_on: Date.current
  },
  {
    title: "Modal Best Practices",
    body: "Modals should be used sparingly and always provide a clear way to dismiss them.",
    publish_on: Date.current + 1.day
  },
  {
    title: "Stimulus Controllers",
    body: "Stimulus is a modest JavaScript framework that connects to your HTML.",
    publish_on: Date.current + 2.days
  },
  {
    title: "Rails and Hotwire",
    body: "Hotwire is an alternative approach to building modern web applications without much JavaScript.",
    publish_on: Date.current + 3.days
  },
  {
    title: "Ultimate Turbo Modal Features",
    body: "Focus trapping, scroll locking, history management, and customizable styling out of the box.",
    publish_on: Date.current + 4.days
  }
]

posts.each do |post_attrs|
  Post.create!(post_attrs)
end

puts "Created #{Post.count} posts"
