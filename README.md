# DeeplinkTool

DeeplinkTool is a command-line tool that processes deeplinks, replaces the scheme, and generates output based on the specified flags. It allows you to modify deeplinks in bulk and supports generating output in both plain text and JSON formats.

## Features

- Replaces the scheme of deeplinks with a custom scheme.
- Generates output in plain text or JSON format.
- Supports grouping deeplinks by base paths for organized output.
- Provides flexibility and customization through command-line flags.

## Installation

To install DeeplinkTool, follow these steps:

1. Clone this repository to your local machine.

2. Open a terminal and navigate to the cloned repository's directory.

3. Run the installation script by executing the following command:

```bash
./install.sh
```

This script will build the Swift package and install the `DeeplinkTool` binary to `/usr/local/bin`.

4. After installation, you can use the `deeplinktool` command in your terminal.

## Usage

DeeplinkTool provides various options for processing deeplinks and generating output. Here are some usage examples:

```shell
# Process deeplinks from a file and generate output in plain text format.
deeplinktool process --file deeplinks.txt --output plain --scheme new-scheme

# Process deeplinks from a file and generate output in JSON format.
deeplinktool process --file deeplinks.txt --output json --scheme new-scheme

# Process deeplinks from a file, group them by base paths, and generate separate output files.
deeplinktool process --file deeplinks.txt --output plain --scheme new-scheme --grouped

# Show the help menu for more options and details.
deeplinktool --help
```

## Command-Line Options
- process: Processes deeplinks based on the specified options.
    - --file: Path to the file containing deeplinks.
    - --output: Specifies the output format (plain or json).
    - --scheme: The custom scheme to replace existing schemes.
    - --grouped: Generates separate output files grouped by base paths.
    - --help: Shows the help menu with command-line options and usage information.

## License
This project is licensed under the MIT License.

```
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

```

## Contributing
Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.
