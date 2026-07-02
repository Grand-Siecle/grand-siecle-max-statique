(: For conditions of distribution and use, see the accompanying legal.txt file. :)

xquery version "3.0";

declare namespace ead="urn:isbn:1-931666-22-9";
declare variable $documentPath external;


    doc($documentPath)//ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt
