# Custom GnuCash 5.x Transaction Report with Tags
## Introduction
This repository contains the custom report version of changes to the default transaction report I am currently working on.

This is a proof of concept related to the long discussed issue around behind able to use analytical dimensions. 
See https://bugs.gnucash.org/show_bug.cgi?id=113772

This proof of concept only focuses on producing a transaction report sorted by user-defined tags. Whether a final version of this report makes it to the official GnuCash release depends on a lot of factors and a lot more testing, user feedback and documentation. 

In the meantime I am making these changes available as a custom report so that users can start using it (if they wish) and provide feedback. For now the best place to provide feedback is on the official Pull Request itself https://github.com/Gnucash/gnucash/pull/1623 

## Installation

This version is offered as a custom report so that users that wish to provide feedback are able to test the feature.

General instructions on how to load custom report are available on the wiki: https://wiki.gnucash.org/wiki/Custom_Reports#Loading_Your_Report

I will provide more specific instructions here soon...

After installation, the custom "Transaction Report with Tags" should be available under the Reports - Experimental menu.

## Report Features

A new tags sort key is made available in the primary and secondary key drop-down list, in the sorting options.

![image](https://github.com/Gnucash/gnucash/assets/267163/89f11c52-5a88-44ad-be61-605c5ec2271e)

To see the transactions grouped by tags, one should select that key as well as enable the subtotal for the level selected.

More options are made available at the bottom of the sorting options.

![image](https://github.com/Gnucash/gnucash/assets/267163/d7adf39d-751b-4a2c-b8de-a8cefd8c3f83)

### Tag Prefix

- By default, the sort engine will look for tags starting with #. However to accomodate the ability to tag multiple dimensions (meaning several tags per transaction), the user is able to change that prefix to any character (even the # could be changed). For instance you could use tags for a project dimension, for instance #P-XXX where XXX is your project reference, so #P-001 #P-002 etc. You could also use tags for different departments so #D for instance, #D-MKTING #D-FINANCE, etc. Then to run a report on the project dimension, set the tag to #P, for the department dimension set the tag to #D. 
- A checkbox allows to select the option to remove the prefix from the subtotal heading, so #D-FINANCE would simply show as FINANCE as the heading for instance (assuming #D- is entered as prefix)
- The tag search is first applied to the split memo, then if no match the transaction notes, then if no match the transaction description. Only the first matched tag (as per the prefix) is considered.

### No-Match Heading
This is the heading that will be used for the subtotal group listing transactions with no match. A checkbox allows to automatically add the prefix to it or not.

## Examples
Here is an example of a report sorted with the defaults on first level. Second level is sorted by account. I am using 2 tags in this sample file: #P-Anna and #P-Bob. Untagged transactions are listed at the bottom in the No Match # section.
![image](https://user-images.githubusercontent.com/267163/235810080-d1ddeb62-291d-42f5-bda2-a32c71fcb69a.png)
![image](https://user-images.githubusercontent.com/267163/235810114-5abecc03-6c4f-4b05-b7eb-bee49d67e549.png)

Here is an example where I change the headings with these options.
![image](https://github.com/Gnucash/gnucash/assets/267163/e60027cd-d543-4ed7-b0a2-26448e161036)

Now my headings are a cleaner Anna, Bob and Nobody.
![image](https://user-images.githubusercontent.com/267163/235810285-6ecd1fda-675a-45ba-943c-be07810fb308.png)
![image](https://user-images.githubusercontent.com/267163/235810305-b187e3c1-5990-4c9f-a09a-fd0664e839dd.png)

It is possible to remove the transactions with no matching tags by using the existing transaction filter (filter tab). Simply put the same tag prefix (# or whatever else you are using) in the Transaction Filter field.
![image](https://user-images.githubusercontent.com/267163/235810409-6d96c353-3e0e-48d3-aede-e4510a9fd62d.png)

Here only Anna and Bob are listed. No-match "Nobody" is no longer there.
![image](https://user-images.githubusercontent.com/267163/235810480-de731104-ab48-4f30-a4dd-6257ef9f7f96.png)

Now I only want to see unmatched transactions.
![image](https://user-images.githubusercontent.com/267163/235812471-4aff7c8b-12f4-454b-b865-eb5d218a9f5b.png)

These are just transactions that are not assigned to anybody
![image](https://user-images.githubusercontent.com/267163/235812541-32044a35-a32a-46ee-9942-228b9b0cc9fe.png)

I could show Anna and Nobody, excluding bob from the view (his transactions are excluded, not in nobody)
![image](https://user-images.githubusercontent.com/267163/235812651-0a44e31f-9151-4252-9789-632d36a00b6b.png)

Here is just Anna and Nobody
![image](https://user-images.githubusercontent.com/267163/235812705-d9a8a4e5-2f4b-4ff4-97c2-b9f0b8b2920e.png)

Many more variations are possible, thanks to the wonderfull filter feature. 

### Credit

**The fact that this feature could be implemented with so little code is made possible by the work of all the gnucash developers that gave us the very versatile and clean structure of the transaction engine we have today. A special thanks to Christopher Lam for his contributions over the last few years in modulizing and cleaning the report as well as providing very kind and pointed advise to a new schemer.**
