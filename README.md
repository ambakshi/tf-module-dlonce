## Terraform Download Once


### Overview

This module is a utility to download a list of files to a directory on the target host. It ensures
that the file is only downloaded once in an atomic way (no partial files when interrupted for example).
The files to be downloaded are most likely specified multiple times (duplicated) so it's important
to get this right in a multithreaded scenario.

Eg, we have a list of terraform resources that use a base vm image (a qcow2 file) that is named after
its contents md5 hash (eg, d3b07384d113edec49eaa6238ad5ff00.qcow2). This allows us to launch many
VMs (for example) using the same base image. In this example, each vm keeps track of what md5sum
its base image is, and if the file doesn't exist, it downloads  it first. The issue this module
aims to solve is that when we launch many vms, we get into a race condition where each vm sees
it's base image is missing and downloads the same file (for the simple case of all vms sharing
the same base image md5), because it doesn't know about the other downloads (it's multiple threads).
Even though we right to a temporary file first then use an atomic rename, each ends up being
downloaded at the same time many times over bringing the network bandwidth to a crawl. One way
to solve this is to have something else (this module!) manage a list of images and it can go throuh
and download the unique images once.

