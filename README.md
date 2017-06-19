# WASP

Web API Specification Protocol (WASP) is a simple language designed to quickly create web APIs. It can be... (design goals and details of language to be added here eventually)

## Team Members

- Manager: Ting Ting Li
- Language Guru: John Chung
- System Architect: Dustin Burge
- Tester: Neel Vadoothker

## Project Proposal

[Google Doc](https://docs.google.com/document/d/1uXqbnIx2ClYijrsMwahpq_mgqRaaDzZHOdCSXaWqW80/edit#)

## 1 Introduction

The WASP language aims to easily and quickly build RESTful ("REST" is short for Representational State Transfer) APIs.
WASP stands for Web API Specification Protocol. It’s a way of describing RESTful APIs in a way that’s highly readable by both humans and computers. WASP focuses on cleanly describing resources, methods, parameters, responses and other HTTP constructs that form the basis for modern APIs that obey the RESTful constraints. It is meant to be simple enough that a
single object definition is enough to create a RESTful backend for that object.

There are two primary use cases for employing WASP. The first is for creating simple RESTful APIs for CRUD (Create, Retrieve, Update, Delete) operations on custom objects. The second is for creating simple calculation based APIs (eg. days until, unit converter, etc.). It is these two use cases that inspired the language and will drive the evolution of WASP throughout its development.
Using WASP to implement a RESTful API is meant to be as simple as defining a struct in C. The details of implementing request routing, object storage, handling HTTP status codes, etc. are
abstracted in favor of the quickest and simplest path to deployment. WASP will be compiled to Go because of its robust built­in networking libraries and the ease of deploying Go server applications

## 2 Language Tutorial

### 2.1 Environment

Since WASP uses the Go programming language ("Go") as its intermediate representation, we need to install Go (https://golang.org/doc/install). Also, the Go intermediate representation uses an HTTP web framework and a MySQL driver for Go's generic interface around SQL databases; so, we will need to install relevant third party Go packages, MySQL and a web server or a stack to run dynamic web sites (e.g. XAMPP, MAMP, WAMP).
Once Go is installed and the GOPATH (https://golang.org/doc/code.html#GOPATH) is set, install the Gin/Gorp, and MySQL third party Go packages.

```
go get github.com/gin-gonic/gin
go get github.com/coopernurse/gorp
go get github.com/go-sql-driver/mysql
```

Before compiling WASP and running Go executables, run the MySQL server. The MySQL port _must_ be set to **8889** for connections to localhost. WASP allows the user to designate the desired TCP port (see section 2.2 below) as long as the default port (e.g. port 80) is avoided. Now, we are ready to use WASP.

### 2.2 Compiling and Running WASP

From the src folder, type `make`. This will create the WASP to Go compiler (wasp executable), which will output Go to standard output given a `.wasp` file. To generate and run the Go executable, type the following:

```
./wasp -g $FILENAME.wasp > $FILENAME.go
PORT = $DESIRED_TCP_PORT go run $FILENAME.go

Specific example:

./wasp -g helloworld.wasp > helloworld.go
PORT = 8080 go run helloworld.go
```
When selecting a TCP port, avoid selecting the default port (e.g. port 80) which the Apache2 http daemon tries to bind to.

### 2.3 Key Features of WASP

The language reference manual in section 3 describes in detail all of WASP's language features. The following highlights some key features.

* At least one `Endpoint` declaration with either a `GET` or `CRUD` operation is mandatory
* Multiple `Endpoint` declarations with either `GET` and/or `CRUD` operations is allowed
* Functions (`Func`) are optional but all Functions require a single `return` statement which must be the last statement in the `Func`
* WASP is statically typed
* WASP allows for a non-primitive type `Object` that is a collection of any number of primitive type variables and/or non-primitive type variables
* WASP allows custom types equivalent to object/endpoint Identifiers
* Comments are are highlighted with `/*` and `*/` but are not nestable
