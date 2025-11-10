# CSS Zero Dummy Application

This is a dummy Rails application used for testing the CSS Zero engine.

## Purpose

This dummy app serves to:
- Test the CSS Zero engine integration with Rails
- Verify Propshaft asset pipeline configuration
- Provide a development environment for testing CSS Zero components
- Demonstrate how to use CSS Zero in a Rails application

## Getting Started

### Setup

```bash
# From the css-zero root directory
bundle install
bin/rails db:prepare
```

### Running the Server

```bash
# From the css-zero root directory
bin/rails server
```

Visit http://localhost:3000 to see the dummy app.

### Running Tests

```bash
# From the css-zero root directory
bin/rails test
```

## Asset Configuration

The dummy app is configured to use Propshaft for asset management. CSS Zero assets are automatically available through the engine's asset pipeline configuration.

### Using CSS Zero Styles

CSS Zero styles are imported in `app/assets/stylesheets/application.css`:

```css
@import "css-zero/variables.css";
@import "css-zero/reset.css";
@import "css-zero/colors.css";
/* ... and more */
```

### Available Assets

- **CSS**: Located in `../../app/assets/stylesheets/css-zero/`
- **JavaScript Controllers**: Located in `../../app/javascript/css_zero/controllers/`
- **Images**: Located in `../../app/assets/images/css_zero/`

## Engine Configuration

The CSS Zero engine is configured in `lib/css_zero/engine.rb` to:
- Automatically add CSS Zero asset paths to the Rails asset pipeline
- Isolate the engine namespace
- Work seamlessly with Propshaft

