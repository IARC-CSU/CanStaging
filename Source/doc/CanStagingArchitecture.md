# CanStaging Architecture

One of the core design of CanStaging principles is the decoupling, of business logic from the software itself as well as the server code from the client code. 

## Business logic

*Decoupling* the business logic, or staging rules, from the software code itself has made it possible for specialists of TNM staging to write the rules without understanding, or interfering with, the underlying source code.

Another key design concept is the use of *naming conventions* to make the business logic as flexible as possible with minimal overhead and duplication of code and data.

### Tables

The business logic of CanStaging is defined in standard text files, or Tables, following naming conventions of codes, variables, and folder structure.

#### Example: Liver TNM 8

The folder *v8/en/Liver_v8/* contains a file called *Liver_v8_T_Meta.txt* with the following content:

```csv
"Field","DataType","DisplayText","Group","Colour"
"Solitary","Dictionary","Solitary or Multiple tumour(s)","2",
"Size","Number","Greatest dimension of the tumour(s)","2",
"Vascular","Dictionary","Vascular invasion","2",
"Invasion","Boolean","Tumour directly invades adjacent organs other than gallbladder","2",
"Visceral","Boolean","Tumour perforates the visceral peritoneum","2",
```

This list the various elements that are needed to calculate the T part of the Liver TNM 8. First the variable, *Field* name, then the *DataType*, then the text that is displayed in the data entry form, *DisplayText*.

The *DataType* can be one of Boolean, Number, or Dictionary.

*Solitary* is of type Dictionary, so another file is expected -- *Liver_v8_Solitary_Dict.txt* -- with the following content:

```csv
"Key","DisplayText"
"1","Solitary tumour"
"2","Multiple tumours"
```

The size field is a number field, so we need a file -- *Liver_v8_T_Size_Range.txt* -- that defines the ranges:

```csv
"Key","Min","Max"
"1","0","0"
"2","0.01","2"
"3","2.01","5"
"4","5.01","999"
```

(Please note that to avoid having to deal with a distinction between inclusive and non inclusive intervals we use arbitrarily small differences in the upper bound of one group and the lower bound of the next. This is not noticeable in the web interface as we round to one digit after comma.)

*Vascular* is another dictionary field and is accompanied by a file called *Liver_T_v8_Vascular_Dict.txt* with a similar structure to the one above.

To calculate the T of Liver the results of these fields are looked up in a file called *Liver_v8_T.txt*:

```csv
"Solitary","Size","Vascular","Invasion","Visceral","Result","Message"
"F","F","1","F","F","T1a",
"1","2","1","F","F","T1a",
"1","2","2","F","F","T1a",
"1","3","1","F","F","T1b",
"1","4","1","F","F","T1b",
"1","3","2","F","F","T2",
"1","4","2","F","F","T2",
"2","2","1","F","F","T2",
"2","2","2","F","F","T2",
"2","3","1","F","F","T2",
"2","3","2","F","F","T2",
"2","4","1","F","F","T3",
"2","4","2","F","F","T3",
"ANY","ANY","3","ANY","ANY","T4",
"ANY","ANY","ANY","T","ANY","T4",
"ANY","ANY","ANY","ANY","T","T4",
```

Here we see that each of the fields from the meta file are input columns, followed by the standard output column *Result*. Any column after this will also be treated like output columns and, for example, added to the result part of the form.

This algorithm looks through the table for _all_ matching rows to calculate the resultsing T-value. 

An important concept is the "ANY" keyword. This matches any value in the correcponding column. So, if we look at last line of the example above we see that if "Visceral" is set to T(rue) it doesn't matter what any of the other values are, the algorithm will always return a T4.

### Xs/Don't know's

Xs are treated differently. The algorithm receives Xs as "Don't know" and does a first pass through the table to see if it matches any lines with explicit Xs in the table. If no possible combination is found we replace the Xs with a default value for each field with an X, before doing another pass to look for possible combinations. These default values are taken from the first line in the respective tables without _any_ X in them. This means that cancers will be _downstaged_ if the first line contains the "least bad" answer, and _upstaged_ if the first line contains the "worst" answer.

---

This pattern is repeated for each of the T, N, M, and SG parts.

To calculate the overall stage group etc there is a file called *Liver_v8_SG.txt*:

```csv
"T","N","M","Result","Message"
"T1a","N0","M0","IA",
"T1b","N0","M0","IB",
"T2","N0","M0","II",
"T3","N0","M0","IIIA",
"T4","N0","M0","IIIB",
"ANY","N1","M0","IVA",
"ANY","ANY","M1","IVB",
```

### Missing data

We have created an algorithm that lets us calculate a range of stage groups if the user doesn't fill the complete form. This can be useful is settings where they are not able to calculate as detailed data as the tool requests.

## Server

The rules files are loaded up in a dedicated server written in Ruby, an open sourced general purpose programming language, leveraging, among others, the Sinatra domain specific language (DSL) [1] for routing, and erb [2] for templating. The server acts both as a web server serving the web interface of the tool as well as an RESTful Application Programmable Interface (API).

### Web interface

The web forms for entering data are dynamically generated from the business logic defined in the files detailed above. Every time any field of the form is changed a REST API request is sent to the servere to update the TNM calculations. This means the user gets instant feedback from the server and can see what each impact each change does. (This aspect of the tool is particularly useful when teaching or learning TNM.) 

### Database

The user can chose submit the records to a database on the server for later download.

### Batch import

The web interface lets users upload data, coded according to the definitions above, in batch mode. This can be a file previously exported from the CanStaging database.

### API

All communications between the web interface and the server application that calculates the TNM is done via standard API calls. This can in principle also be used by other applications, ie. cancer registry software.

## Stand alone application

The tool can also be installed on a personal computer for offline work, whilst still operating in the same way as the online tool using a web browser for data entry.

## References

- [1] http://sinatrarb.com/
- [2] https://ruby-doc.org/stdlib-2.7.1/libdoc/erb/rdoc/ERB.html