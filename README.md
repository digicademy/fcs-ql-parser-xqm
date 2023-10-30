
# cql-parser-xqm

This software package provides an XQuery module developed at the Digital Academy of the Academy of Sciences and Literature | Mainz that may be used to parse [FCS-QL](https://office.clarin.eu/v/CE-2017-1046-FCS-Specification-v89.pdf) and transform FCS-QL queries into a custom XML format that matches the [provided schema](schema/query.rng).

Please note that this parser does not yet support the following FCS-QL features:

* Main Queries with disjunctions => e.g. `"lorem" | [text = "ipsum"]`
* Sequence Queries => e.g. `"lorem" [text = "ipsum"]`
* Groupings => e.g. `("lorem")`
* Quantifiers => e.g. `"lorem"{,3}`
* Negated expressions => e.g. `[!text = "ipsum"]`


# Requirements
The module was developed and tested to be used with the versions 3.1 of XQuery.

# How to Use
1. Import the module into your own XQuery script or module in the usual way:

```xquery
import module namespace fcs-ql-parser="http://mwb.adwmainz.net/exist/fcs/fcs-ql-parser" at "PATH/TO/fcs-ql-parser.xqm";
```

2. Use the following function:

## fcs-ql-parser:parse

```xquery
fcs-ql-parser:parse($query as xs:string?) as element(query)?
```

transforms a CLARIN FCS-QL query into a query element

### Parameters:

**$query?** a query following the syntax of FCS-QL (c.f. https://office.clarin.eu/v/CE-2017-1046-FCS-Specification-v89.pdf) - e.g. `"lorem"` or `[lemma = "ipsum"/l & pos='ADJ']`

### Returns:

**element(query)?** an XML equivalent - e.g.

```xml
<query>
    <segment>
        <expression>
            <attribute>text</attribute>
            <operator>=</operator>
            <regexp>lorem</regexp>
        </expression>
    </segment>
</query>
```
or
```xml
<searchClause xmlns="http://www.loc.gov/zing/cql/xcql/">
    <index>c.title</index>
    <relation>
        <value>any</value>
    </relation>
    <term>fish frog</term>
</searchClause>
```
or
```xml
<triple xmlns="http://www.loc.gov/zing/cql/xcql/">
    <Boolean>
        <value>or</value>
    </Boolean>
    <leftOperand>
        <searchClause>
            <index>cql.serverChoice</index>
            <relation>
                <value>=</value>
            </relation>
            <term>cat</term>
        </searchClause>
    </leftOperand>
    <rightOperand>
        <searchClause>
            <index>cql.serverChoice</index>
            <relation>
                <value>=</value>
            </relation>
            <term>dog</term>
        </searchClause>
    </rightOperand>
</triple>
```

---

# License
The software is published under the terms of the MIT license.


# Research Software Engineering and Development

Copyright 2023 <a href="https://orcid.org/0000-0002-5843-7577">Patrick Daniel Brookshire</a>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
