locals {
  sshPrivateKeyFilename = abspath(pathexpand("~/.ssh/id_rsa"))
  sshPublicKeyFilename = abspath(pathexpand("~/.ssh/id_rsa.pub"))
}