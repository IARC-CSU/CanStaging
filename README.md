# CanStaging+

## Stand-alone Tool

### Installation

#### Install Ruby on Windows

Download from installer http://railsinstaller.org/en and run it.

#### Install Ruby on Linux

Debian-based distributions (Ubuntu/Pop_OS!/etc): ```apt install ruby``` followed by ```gem install bundler```

#### Install necessary libraries

Open a terminal/command line, navigate to the Source folder and run ```bundle install```.

## Configuration

### Keys

You need to set up the file with the keys for accessing the tool. This should be called "keyfile.txt" and follow the same structure as the "keyfile-example.txt" in the Source folder. (You can, for testing/development just make a copy of the example file.)

### Port

You can set the tool to use another port than the default port 80 by changing it in the config.yml file.

## Run

### Start the stand-alone server

Execute ```ruby WebService.rb``` in the Source folder.

### Access Stand alone tool

Navigate to http://localhost:80 using your favourite browser. (If that happens _not_ to be Internet Explorer.)

## Generate .exe

```ocra --gem-full WebService.rb views/* public/*```

Files and folders needed by resulting executable:

- i18n
- Tables
- config.yml
- keyfile.txt

