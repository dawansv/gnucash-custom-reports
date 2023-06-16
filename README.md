# Custom Reports for GnuCash 5.x

  * [Introduction](#introduction)
  * [Installation](#installation)
  * [Report Features](#report-features)

## Introduction

This is repository contains a series of custom reports for GnuCash 5.x.

### Transaction Report Extended

**Filename**: transaction-extended.scm

**Description**: Based on the built-in transaction report, it provides a Sort by Substring option which includes a regular expression match similar to the one offered for the transaction filter. That feature is the generic version of the Transaction Report with Tags.

### Transaction Report with Tags

**Filename**: transaction-tags.scm

**Description**: An earlier version of transaction-extended.scm that focusses on Sort by tags specifically. It was releases as a proof-of-concept to provide some basic features related to the long-discussed request of being able to use orthogonal categories, classes, tags or "analytical dimensions" to retrieve and group transactions across several general ledger accounts. See https://bugs.gnucash.org/show_bug.cgi?id=113772

**Limitations**: This custom report is not a feature-rich solution. It only provides one type of report (similar to the existing transaction report) and does not provide any feature to "bulk manage" existing or future user-defined tags. So there is no feature to bulk rename, bulk move or bulk delete tags for instance. All changes to the data file (adding and changing tags) are done manually by the user. This feature only provides a custom report that uses tags as created by the user.

## Installation

Custom reports can be easily installed and uninstalled and do not modify the core GnuCash files nor the data file.

Specific instructions below are based on more generic instructions on how to load custom reports available on the wiki: https://wiki.gnucash.org/wiki/Custom_Reports#Loading_Your_Report

### Step 1. Download and Unzip the files

Download the zip with the files from the Github Code button. Then unzip the files in a temporary directory.

![image](https://github.com/dawansv/gnucash-transaction-tags/assets/267163/c59f5e03-ba77-4fdb-afbf-94fe75737959)

### Step 2. Copy transaction-tags.scm in the installation directory for custom reports

1. Start GnuCash 5.0
2. Go to menu Help - About
3. In the About GnuCash dialog, locate the entry for **GNC_USERDATA_DIR**. It's the first entry in the list. Keep note of this directory. You can even click on the link to open it.
4. Copy the _[report-filename].scm_ files of your choosing extracted from the zip file into that directory.

### Step 3. Locate the installation directory for the custom reports definition file (config-user.scm)

Custom reports need to be initialized in a config file called _config-user.scm_

Go back to the _About GnuCash_ dialog from Step 2. 

This time locate the **second** entry **GNC_USERCONFIG_DIR**. Click on the link to open the directory.

### Step 4. Update or create config-user.scm

If there is **already** an existing file called _config-user.scm_ in the directory from Step 3 then you need to edit that file and add this line to it:

`(load (gnc-build-userdata-path "[report-filename].scm"))`

If there **isn't** a file called _config-user.scm_ in that directory, then you can either create one and put the above line in it or you can simply use the file that came with the zip file.

### Step 5. Restart GnuCash

After restarting GnuCash, the custom "Transaction Report with Tags" should be available under the Reports - Experimental menu.

## Report Features 

#### Transaction Report Extended

(TO DO)

#### Transaction Report with Tags

A new tags sort key is made available in the primary and secondary key drop-down list, in the sorting options.

![image](https://github.com/Gnucash/gnucash/assets/267163/89f11c52-5a88-44ad-be61-605c5ec2271e)

To see the transactions grouped by tags, one should select that key as well as enable the subtotal for the level selected.

More options are made available at the bottom of the sorting options.

![image](https://github.com/Gnucash/gnucash/assets/267163/d7adf39d-751b-4a2c-b8de-a8cefd8c3f83)

#### Tag Prefix

- By default, the sort engine will look for tags starting with #. However to accomodate the ability to tag multiple dimensions (meaning several tags per transaction), the user is able to change that prefix to any character (even the # could be changed). For instance you could use tags for a project dimension, for instance #P-XXX where XXX is your project reference, so #P-001 #P-002 etc. You could also use tags for different departments so #D for instance, #D-MKTING #D-FINANCE, etc. Then to run a report on the project dimension, set the tag to #P, for the department dimension set the tag to #D. 
- A checkbox allows to select the option to remove the prefix from the subtotal heading, so #D-FINANCE would simply show as FINANCE as the heading for instance (assuming #D- is entered as prefix)
- The tag search is first applied to the split memo, then if no match the transaction notes, then if no match the transaction description. Only the first matched tag (as per the prefix) is considered.

#### No-Match Heading
This is the heading that will be used for the subtotal group listing transactions with no match. A checkbox allows to automatically add the prefix to it or not.

#### Examples
Here is an example of a report sorted with the defaults on first level. Second level is sorted by account. I am using 2 tags in this sample file: #P-Anna and #P-Bob. Untagged transactions are listed at the bottom in the No Match # section.
![image](https://user-images.githubusercontent.com/267163/235810080-d1ddeb62-291d-42f5-bda2-a32c71fcb69a.png)
![image](https://user-images.githubusercontent.com/267163/235810114-5abecc03-6c4f-4b05-b7eb-bee49d67e549.png)

Here is an example where I change the headings with these options.
![image](https://github.com/Gnucash/gnucash/assets/267163/e60027cd-d543-4ed7-b0a2-26448e161036)

Now my headings are a cleaner Anna, Bob and Nobody.
![image](https://user-images.githubusercontent.com/267163/235810285-6ecd1fda-675a-45ba-943c-be07810fb308.png)
![image](https://user-images.githubusercontent.com/267163/235810305-b187e3c1-5990-4c9f-a09a-fd0664e839dd.png)

It is possible to remove the transactions with no matching tags by using the existing transaction filter (filter tab). Simply put the same tag prefix (# or whatever else you are using) in the Transaction Filter field.
![image](https://github.com/dawansv/gnucash-transaction-tags/assets/267163/cf5dc927-9534-46db-aa2c-c1bd88e47f79)

Here only Anna and Bob are listed. No-match "Nobody" is no longer there.
![image](https://user-images.githubusercontent.com/267163/235810480-de731104-ab48-4f30-a4dd-6257ef9f7f96.png)

Now I only want to see unmatched transactions.
![image](https://github.com/dawansv/gnucash-transaction-tags/assets/267163/2da6ae6c-2631-47a8-b92b-b4ea0f803945)

These are just transactions that are not assigned to anybody
![image](https://user-images.githubusercontent.com/267163/235812541-32044a35-a32a-46ee-9942-228b9b0cc9fe.png)

I could show Anna and Nobody, excluding Bob from the view (his transactions are excluded, not in nobody)
![image](https://github.com/dawansv/gnucash-transaction-tags/assets/267163/37809e83-6c00-42b9-b27e-a2bb9fd164a5)

Here is just Anna and Nobody
![image](https://user-images.githubusercontent.com/267163/235812705-d9a8a4e5-2f4b-4ff4-97c2-b9f0b8b2920e.png)

Many more variations are possible, thanks to the wonderfull filter feature. 
