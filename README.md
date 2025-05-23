# SVNBackup

This project is for utilizing [SVN](https://subversion.apache.org/) as a backup mechanism for your home directory.

While SVN can be used as a passive folder, Apache was chosen so that a multi-user system can limit access to each user.

This is exclusively for **Windows** and exclusively localhost. Linux and webservers are out of scope (and much easier to install).

## Installation

1. Run `Install-Apache.ps1` for the underlying localhost webserver
1. Run `Install-SVNBackup.ps1` for the SVNBackup extension

## Usage

You **MUST** add Windows users through the `Add-User.ps1` (copied to your chosen install path).
Failure to do so means manually performing the steps within the script to add SVN access.

This will install a script that will automatically update your home directory upon login to ensure you are on the latest version.

I recommend using [TortoiseSVN](https://tortoisesvn.net/) for managing the monitoring and checking in the content of your files.
