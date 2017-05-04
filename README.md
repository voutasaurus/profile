# profile

This is a collection of bash aliases and functions for MacOSX.

# install

(note: some of these require Go to be installed: https://golang.org/dl/)

Download the file
```
$ cd $HOME
$ git clone https://github.com/voutasaurus/profile .dot
```

Add the following lines to your $HOME/.bash_profile
```
if [ -f $HOME/.dot/profile ]
then . $HOME/.dot/profile
fi
```
