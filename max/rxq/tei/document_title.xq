(: For conditions of distribution and use, see the accompanying legal.txt file. :)

xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare variable $documentPath external;


if(doc($documentPath)/tei:teiCorpus)
then
    doc($documentPath)/tei:teiCorpus/tei:teiHeader/tei:fileDesc/tei:titleStmt
else
    doc($documentPath)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt

