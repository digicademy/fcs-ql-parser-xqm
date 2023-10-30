xquery version "3.1";

(:
 : MWB | FCS-QL parser
 :
 : Edited and developed by Patrick D. Brookshire and Ute Recker-Hamm
 : Academy of Sciences and Literature | Mainz
 :
 : xquery module containing various functions used for parsing FCS-QL queries (c.f. https://office.clarin.eu/v/CE-2017-1046-FCS-Specification-v89.pdf)
 :
 : @author Patrick D. Brookshire
 : @licence MIT
:)

module namespace fcs-ql-parser="http://mwb.adwmainz.net/exist/fcs/fcs-ql-parser";

declare variable $fcs-ql-parser:error-namespace := "http://fcs-ql.parser/err";

declare variable $fcs-ql-parser:default-attribute := "text";
declare variable $fcs-ql-parser:default-operator := "=";

declare %private variable $fcs-ql-parser:quoted-str-pattern := "((?:'(?:[^ ]+?)')" || "|" || '(?:"(?:[^ ]+?)"))';
declare %private variable $fcs-ql-parser:flagged-regexp-pattern := $fcs-ql-parser:quoted-str-pattern || " *(?:/([iIcCld]+))?";

declare %private variable $fcs-ql-parser:identifier-first-char-pattern := '[a-zA-Z]';
declare %private variable $fcs-ql-parser:identifier-char-pattern := '[a-zA-Z0-9\-]';
declare %private variable $fcs-ql-parser:identifier-pattern := $fcs-ql-parser:identifier-first-char-pattern || $fcs-ql-parser:identifier-char-pattern || "*";
declare %private variable $fcs-ql-parser:attribute-pattern := "(?:" || $fcs-ql-parser:identifier-pattern || ":)?" || $fcs-ql-parser:identifier-pattern;
declare %private variable $fcs-ql-parser:operator-pattern := "!?=";
declare %private variable $fcs-ql-parser:basic-expression-pattern := "(" || $fcs-ql-parser:attribute-pattern || ") *?(" || $fcs-ql-parser:operator-pattern || ") *?" || $fcs-ql-parser:flagged-regexp-pattern;
declare %private variable $fcs-ql-parser:basic-boolean-pattern := "(" || $fcs-ql-parser:basic-expression-pattern || ")( *?[&amp;|] *?" || $fcs-ql-parser:basic-expression-pattern || ")+";
declare %private variable $fcs-ql-parser:quantification-pattern := "(\+|\*|\?|\{ *[0-9] *,? *\}|\{ *[0-9]? *, *[0-9] *\})";

declare %private variable $fcs-ql-parser:simple-quoted-query-pattern := "^ *" || $fcs-ql-parser:flagged-regexp-pattern || " *$";
declare %private variable $fcs-ql-parser:simple-segment-query-pattern := "^ *" || "\[ *" || $fcs-ql-parser:basic-expression-pattern || " *\]" || " *$";
declare %private variable $fcs-ql-parser:boolean-segment-query-pattern := "^ *" || "\[ *" || $fcs-ql-parser:basic-boolean-pattern || " *\]" || " *$";
declare %private variable $fcs-ql-parser:within-query-pattern := "^(.*?) within (.+?)$";

(: local serialization helper methods :)
declare %private function fcs-ql-parser:get-scope($query as xs:string?) as element(scope)? {
    if (matches($query, $fcs-ql-parser:within-query-pattern)) then
        <scope>{ normalize-space(replace($query, $fcs-ql-parser:within-query-pattern, "$2")) }</scope>
    else
        ()
};

declare %private function fcs-ql-parser:remove-scope($query as xs:string?) as xs:string? {
    if (matches($query, $fcs-ql-parser:within-query-pattern)) then
        replace($query, $fcs-ql-parser:within-query-pattern, "$1")
    else
        $query
};

declare %private function fcs-ql-parser:parse-implicit-query($query as xs:string?) as element(segment)? {
    let $regexp := replace($query, $fcs-ql-parser:simple-quoted-query-pattern, "$1")
    let $flags := replace($query, $fcs-ql-parser:simple-quoted-query-pattern, "$2")
    return
        <segment>
            <expression>
                <attribute>{ $fcs-ql-parser:default-attribute }</attribute>
                <operator>{ $fcs-ql-parser:default-operator }</operator>
                { fcs-ql-parser:build-regexp($regexp, $flags) }
            </expression>
        </segment>
};

declare %private function fcs-ql-parser:parse-segment($query as xs:string?) as element(segment)? {
    let $query := replace($query, "^ *\[ *(.*?) *\] *$", "$1")
    return
        <segment>{ fcs-ql-parser:build-boolean-expression($query) }</segment>
};

declare %private function fcs-ql-parser:build-boolean-expression($query) {
    (: TODO: parse complex left-expression with `not` and groupings :)
    let $left-expression := replace($query, $fcs-ql-parser:basic-boolean-pattern, "$1")
    let $expression-length := string-length($left-expression)
    return
        if ($expression-length eq string-length($query)) then
            fcs-ql-parser:parse-expression($left-expression)
        else
            let $remaining-expression := replace(substring-after($query, $left-expression), "^ *(.*)$", "$1")
            let $operator := substring($remaining-expression, 1, 1)
            let $right-expression := replace(substring-after($query, $operator), "^ *(.*) *$", "$1")
            return
                <boolean>
                    <operator>{
                        if (($operator) eq "&amp;") then
                            "and"
                        else if (($operator) eq "|") then
                            "or"
                        else
                            $operator
                    }</operator>
                    { fcs-ql-parser:parse-expression($left-expression) }
                    { fcs-ql-parser:build-boolean-expression($right-expression) }
                </boolean>
};

declare %private function fcs-ql-parser:parse-expression($query as xs:string?) as element(expression)? {
    let $attribute := replace($query, $fcs-ql-parser:basic-expression-pattern, "$1")
    let $operator := replace($query, $fcs-ql-parser:basic-expression-pattern, "$2")
    let $regexp := replace($query, $fcs-ql-parser:basic-expression-pattern, "$3")
    let $flags := replace($query, $fcs-ql-parser:basic-expression-pattern, "$4")
    return
        <expression>
            <attribute>{ $attribute }</attribute>
            <operator>{ $operator }</operator>
            { fcs-ql-parser:build-regexp($regexp, $flags) }
        </expression>
};

declare %private function fcs-ql-parser:build-regexp($regexp as xs:string?, $flags as xs:string?) as element(regexp)? {
    if (not(fcs-ql-parser:is-valid-regex($regexp))) then
        error() (: ignore invalid RegEx:)
    else
        <regexp>
            {
                if ($flags ne "") then
                    attribute flags { $flags }
                else
                    ()
            }
            {
                if (substring($regexp, 1, 1) eq "'") then
                    replace(substring($regexp, 2, string-length($regexp) - 2), "\\'", "'")
                else
                    replace(substring($regexp, 2, string-length($regexp) - 2), '\\"', '"')
            }
        </regexp>
};

declare %private function fcs-ql-parser:is-valid-regex($regexp as xs:string?) as xs:boolean {
    try {
        let $test := matches("test", $regexp)
        return
            true()
    } catch * {
        false()
    }
};

declare %private function fcs-ql-parser:get-quantification-attrs($quantification as xs:string) as attribute()* {
    let $quantification := replace($quantification, "[ {}]", "")
    return
        switch ($quantification)
            case "?" return (
                attribute min { "0" },
                attribute max { "1" }
            ) case "*" return (
                attribute min { "0" },
                attribute max { "unbound" }
            ) case "+" return (
                attribute min { "1" },
                attribute max { "unbound" }
            ) default return
                if ($quantification castable as xs:integer) then (
                    attribute min { $quantification },
                    attribute max { $quantification }
                ) else (
                    attribute min { (substring-before($quantification, ",")[not(. = "")], "0")[1] },
                    attribute max { (substring-after($quantification, ",")[not(. = "")], "unbound")[1] }
                )
};


(: MAIN PARSER FUNCTION :)
(:~ transforms a CLARIN FCS-QL query into a query element
 : @param $query a query following the syntax of FCS-QL (c.f. https://office.clarin.eu/v/CE-2017-1046-FCS-Specification-v20230426.pdf)
 : @error this function may raise an FCS-QL Error if the given query cannot be parsed
 : @todo: add support for or queries
 : @todo: add support for sequence queries
 : @todo: add support for quantification
 : @todo: add support for groupings
 : @todo: add support for not expressions
:)
declare function fcs-ql-parser:parse($query as xs:string?) as element(query)? {
    if (normalize-space($query) eq "") then
        ()
    else
        try {
            let $scope := fcs-ql-parser:get-scope($query)
            let $query := fcs-ql-parser:remove-scope($query)
            return
                if ( matches($query, $fcs-ql-parser:boolean-segment-query-pattern) ) then
                    <query>
                        { fcs-ql-parser:parse-segment($query) }
                        { $scope }
                    </query>
                else if ( matches($query, $fcs-ql-parser:simple-segment-query-pattern) ) then
                    <query>
                        { fcs-ql-parser:parse-segment($query) }
                        { $scope }
                    </query>
                else if ( matches($query, $fcs-ql-parser:simple-quoted-query-pattern) ) then
                    <query>
                        { fcs-ql-parser:parse-implicit-query($query) }
                        { $scope }
                    </query>
                else
                    error(QName($fcs-ql-parser:error-namespace, "FCS-QL-Error"), "Query could not be parsed")
        } catch * {
            error(QName($fcs-ql-parser:error-namespace, "FCS-QL-Error"), "Query could not be parsed")
        }
};
