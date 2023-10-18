#lang scribble/manual

@(require (for-label amb-parser
                     racket)
          amb-parser
          racket)

@title{amb-parser: Parser generator for ambiguous grammars}
@author{Ruslan Popov}

@defmodulelang[amb-parser]

@section{Introduction}

This is a very simple parser generator that mimics @racketmodname[brag] (and actually its built on top of it).
It is designed for parsing English text.

Its main features are:
@itemlist[@item{Ambiguous grammar support. Parser generates all possible derivation trees.}
          @item{Support for tokens that have multiple types attached. For example, the word @tt{cook} in English may be either a verb or a noun.}]

I don't know whether the implementation works correctly.

@section{Parser language}
The language for @racketmodname[amb-parser] is similar to one in @racketmodname[brag], but with several differences:
@itemlist[@item{Semicolon is required at the end of a production.}
          @item{Terminals are written in lowercase, non-terminals are in uppercase.}]

Note: the parser does not support left-recursion. (Yet Another Parser that Doesn't Support Left Recursion, @tt{yapdslr}).

Example:
@codeblock{
 #lang amb-parser
 S : NP VP;
 NP : determiner? adjective* noun;
 VP : verb NP;
}

The parser supports ONLY:
@itemlist[@item{Rule combinations: @verbatim{S : NP VP;}}
          @item{Optional rule: @verbatim{NP : determiner? noun;}}
          @item{Kleene star rule: @verbatim{NP : adjective* noun;}}
          @item{Alteration on the top level of an expansion: @verbatim{A : b | c;}}]

Note: the parser does not support grouping.

Note: you are allowed to combine question and star operators only in the order: @tt{rule*?}.

@subsection{Formal parser language definition}
@codeblock{
#lang brag

parser-syntax : rule+

rule : NON-TERMINAL COLON alteration SEMICOLON

alteration : expansion (ALTERATION expansion)*
expansion : (non-terminal | terminal)*

non-terminal : NON-TERMINAL [STAR] [QUESTION]
terminal : TERMINAL [STAR] [QUESTION]
}

@section[#:tag "parser-interface"]{Parser interface}
@itemlist[@item{Firstly, import @racket[amb-parser] in your Racket module.}
          @item{Then create a file with @verbatim{#lang amb-parser} line and with your grammar and require it in your Racket module.}]
 
You will be provided with the @racket[parse] function. You can use this function to parse your text. But before, your text should be separated into tokens.

For more details, refer to the @racket[parse] documentation.

@section{Usage example}
Let's take the grammar in @secref["parser-interface"]:
@codeblock{
 #lang amb-parser
 S : NP VP;
 NP : determiner? adjective* noun;
 VP : verb NP;
}

For sentence @code{"The big cat catched a small grey mouse."}, which is transformed in the list of tokens:
@codeblock{
 (list
   (token "the" '(determiner))
   (token "big" '(adjective))
   (token "cat" '(noun))
   (token "catched" '(verb))
   (token "a" '(determiner))
   (token "small" '(adjective))
   (token "grey" '(adjective))
   (token "mouse" '(noun)))
}

The parser will generate such a result:
@codeblock{
 (list
   (parser-result
     '(S
        (NP (determiner "the")
            (adjective* (adjective "big") (adjective*))
            (noun "cat"))
        (VP
          (verb "catched")
          (NP
            (determiner "a")
            (adjective* (adjective "small") (adjective* (adjective "grey") (adjective*)))
            (noun "mouse"))))
     '()))
}

Note how the star rule works.

@section{Parse tree structure}
In this section we will describe the structure of the parse tree without specifying that the parser
returns multiple results and every @racket[parser-result] contains the rest of tokens.

@itemlist[@item{Every rule @tt{name : expansion;} will be parsed as @tt{(name expansion)}.}
          @item{Every expansion @tt{rule1 rule2} will be parsed as an association list, where keys and values
           are organized as list with two elements, keys are rule names and values are the result of
           parsing the rules.}
          @item{Every terminal @tt{terminal} will be parsed as @tt{(list 'terminal token-str)} where
           @tt{token-str} is the string of the matched token.}]

If some parsing is failed then the @racket[parse] returns @racket[empty] (meaning there is no
derivation trees and no parser results).

@section{Types and functions}

@subsection{Tokens}

@defstruct*[token ([str string?] [pos (listof symbol?)]) #:transparent ]{

Represents a token.

@racket[pos] is a list of all possible parts of speech for this token.

When parser tries to parse a terminal rule it checks whether the terminal is a member of @racket[pos] list.

Note: in fact, the implementation does not really utilizes the info that the @racket[str] is a @racket[string?].

}

@defproc[(token? [x any/c])
         boolean?]{
Returns whether the @racket[x] is a @racket[token].
}

@defproc[(token-str [token token?])
         string?]{
Returns the string of the @racket[token].
}

@defproc[(token-pos [token token?])
         (listof symbol?)]{
Returns all possible parts of speech for the @racket[token].
}

@subsection{Parser result}

@defstruct*[parser-result ([data any/c] [rest (listof token?)]) #:transparent ]{
Represents a single result of parsing. It consists of parsed @tt{data} and the @tt{rest} of tokens (uparsed part).
}

@defproc[(parser-result? [x any/c])
         boolean?]{
Returns whether the @racket[x] is a @racket[parser-result].
}

@defproc[(parser-result-data [res parser-result?])
         any/c]{
Returns the parsed data of the @racket[res].
}

@defproc[(parser-result-rest [res parser-result?])
         (listof token?)]{
Returns the uparsed tokens of the @racket[res].
}

@subsection{Parsing}

@defproc[(parse [non-terminal symbol?] [tokens (listof token?)])
         (listof parser-result?)]{

Parses @racket[non-terminal] from the @racket[tokens] list.

Parser returns a list of all possible derivation trees. The results are organized into @racket[parser-result] structures.

WARNING: There is a bad design desicion. The @racket[parse] function requires a list of tokens, instead of a lambda function that generates tokens on demand.}
