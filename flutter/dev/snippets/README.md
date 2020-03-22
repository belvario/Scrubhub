# Dartdoc Generation

The Flutter API documentation contains code blocks that help provide
context or a good starting point when learning to use any of Flutter's APIs.

To generate these code blocks, Flutter uses dartdoc tools to turn documentation
in the source code into API documentation, as seen on https://api.flutter.dev/.

## Table of Contents

- [Types of code blocks](#types-of-code-blocks)
  - [Sample tool](#sample-tool)
  - [Snippet tool](#snippet-tool)
- [Skeletons](#skeletons)
- [Test Doc Generation Workflow](#test-doc-generation-workflow)
## Types of code blocks

### Sample Tool

![Code sample image](assets/code_sample.png)

The code `sample` tool generates a block containing a description and example
code. Here is an example of the code `sample` tool in use:

```dart
/// {@tool sample}
///
/// If the avatar is to have an image, the image should be specified in the
/// [backgroundImage] property:
///
/// ```dart
/// CircleAvatar(
///   backgroundImage: NetworkImage(userAvatarUrl),
/// )
/// ```
/// {@end-tool}
```

This will generate sample code that can be copied to the clipboard and added
to existing applications.

This uses the skeleton for [sample](config/skeletons/sample.html) snippets.

### Snippet Tool

![Code snippet image](assets/code_snippet.png)

The code `snippet` tool can expand sample code into full Flutter applications.
These sample applications can be directly copied and used to demonstrate the
API's functionality in a sample application:

```dart
/// {@tool snippet --template=stateless_widget_material}
/// This example shows how to make a simple [FloatingActionButton] in a
/// [Scaffold], with a pink [backgroundColor] and a thumbs up [Icon].
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: Text('Floating Action Button Sample'),
///     ),
///     body: Center(
///       child: Text('Press the button below!')
///     ),
///     floatingActionButton: FloatingActionButton(
///       onPressed: () {
///         // Add your onPressed code here!
///       },
///       child: Icon(Icons.thumb_up),
///       backgroundColor: Colors.pink,
///     ),
///   );
/// }
/// ```
/// {@end-tool}
```

This uses the skeleton for [application](config/skeletons/application.html)
snippets.

Code `snippets` also allow for quick Flutter app generation using the following command:

```bash
flutter create --sample=[directory.File.sampleNumber] [name_of_project_directory]
```

#### Templates

In order to support showing an entire app when you click on the right tab of
the code snippet UI, we have to be able to insert the `snippet` into the template
and instantiate the right parts.

To do this, there is a [config/templates](config/templates) directory that
contains a list of templates. These templates represent an entire app that the
`snippet` can be placed into, basically a replacement for `lib/main.dart` in a
flutter app package.

For more information about how to create, use, or update templates, see
[config/templates/README.md](config/templates/README.md).

## Skeletons

A skeleton (in relation to this tool) is an HTML template into which the Dart
code blocks and descriptions are interpolated.

There is currently one skeleton for
[application](config/skeletons/application.html) `snippets` and one for
[sample](config/skeletons/sample.html) `snippets`, but there could be more.

Skeletons use mustache notation (e.g. `{{code}}`) to mark where components will
be interpolated into the template. It doesn't actually use the mustache
package, since these are simple string substitutions, but it uses the same
syntax.

The code block generation tools process the source input and emit HTML for output,
which dartdoc places back into the documentation. Any options given to the
 `{@tool ...}` directive are passed on verbatim to the tool.

The `snippets` tool renders these examples through a combination of markdown
and HTML using the `{@inject-html}` dartdoc directive.

## Test Doc Generation Workflow

If you are making changes to an existing code block or are creating a new code
block, follow these steps to generate a local copy of the API docs and verify
that your code blocks are showing up correctly:

1. Make an update to a code block or create a new code block.
2. From the root directory, run `./dev/bots/docs.sh`. This should start
generating a local copy of the API documentation.
3. Once complete, check `./dev/docs/doc` to check your API documentation. The
search bar will not work locally, so open `./dev/docs/doc/index.html` to
navigate through the documentation, or search `./dev/docs/doc/flutter` for your
page of interest.
