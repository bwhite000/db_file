DbFile Changelog
================

v0.0.3 (9.12.2015)
------------------
* Testing an updating to get the features working again and implement some
  that were not completely finished.
* Moved everything to currently being in-memory, and not accessing the file
  when needed, like before; will re-implement the on-disk-only version again
  soon.
* Added an init method to load the information into memory before using the DB
  table.
* Tons of major improvements from the last release for data types, encoding,
  and sticking to the idea of saving as CSVs and not MongoDB style Objects (at
  this time), like I was experimenting with in the last release.

v0.0.2 (6.3.2015)
-----------------
* Changing method names and adding new methods for better data interaction
  and the ability to add new data.

v0.0.1 (5.20.2015)
------------------
* Created the original DbFile class.
* [6.2.2015] Moved the original class from another file into this package.