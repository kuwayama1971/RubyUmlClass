# RubyUmlClass

RubyUmlClass creates a Ruby class diagram.  
PlantUML and rufo commands are used to create class diagrams.  
The generated class diagram is displayed on the browser screen.  

## Setup

for Ubuntu  
```sh
$ sudo apt install plantuml
```

for Windows  
Install Java and PlantUML.  
Set java and plantuml.jar in [PlantUML Command].  
You can also use the PlantUML extension function of VSCode.  

Set [RubyUmlClass => Setting => PlantUML Command] as follows:  
```
java -jar C:/Users/%USERNAME%/.vscode/extensions/jebbs.plantuml-2.17.5/plantuml.jar -svg --charset UTF-8
```

## Installation

Install the gem and add to the application's Gemfile by executing:

```sh
$ bundle add ruby_uml_class
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
$ gem install ruby_uml_class
```

## Usage

```sh
$ start_ruby_uml_class.rb
```

https://user-images.githubusercontent.com/88954426/211500980-3bb839a9-8cf5-44da-b8f9-733a87f22c96.mp4

---

## Main Changes from v0.6.0 to v0.6.1

- **Major UI/Design Update**  
  - Modernized color scheme, layout, buttons, and menu design
  - Improved settings dialog and log display
- **Improvements to Settings/File Selection Dialogs**  
  - Automatic dialog size adjustment, support for textarea settings (such as JSON input)
  - Enhanced input assistance and validation
- **Functional Improvements**  
  - Enhanced parent directory (../) selection when choosing files
  - Simplified editor launch process
- **Changes to Server Port and Browser Launch Command**  
  - Support for multiple browsers (Edge/Chrome on Windows, Chromium on Linux, etc.)
  - Changed default WebSocket port
- **Version Up**  
  - Bumped version from 0.6.0 to 0.6.1

---

## Development

To install this gem onto your local machine, run `bundle exec rake install`.  
To release a new version, update the version number in `version.rb`, and then run  
`bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kuwayama1971/RubyUmlClass.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
