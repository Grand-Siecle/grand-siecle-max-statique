(: For conditions of distribution and use, see the accompanying legal.txt file. :)

module namespace max.cons = 'pddn/max/cons';

declare variable $max.cons:TEI := "tei";
declare variable $max.cons:EAD := "ead";

(: Base Dir:)
declare variable $max.cons:BASE_DIR := "/";

(: TOC path name (in URLs):)
declare variable $max.cons:TOC := "sommaire";

declare variable $max.cons:TEXT_ID := "text";

(: MENU file path. :)
declare variable $max.cons:MENU_FILE := "menu.xml";

(: plugins' folder. :)
declare variable $max.cons:PLUGIN_FOLDER_NAME := "plugins";

(: menu XSL. :)
declare variable $max.cons:MENU_XSL_FILEPATH := "ui/xsl/core/menu.xsl";

(: project toc query :)
declare variable $max.cons:TOC_QUERY_FILEPATH := "xq/toc.xq";

(: document toc query :)
declare variable $max.cons:DOCUMENT_TOC_QUERY_FILENAME := "document_toc.xq";

(: document title query :)
declare variable $max.cons:DOCUMENT_TITLE_QUERY_FILENAME := "document_title.xq";

(: document toc query :)
declare variable $max.cons:DOCUMENT_TOC_QUERY_FILEPATH := "xq/"||$max.cons:DOCUMENT_TOC_QUERY_FILENAME;

(: metadata query :)
declare variable $max.cons:METADATA_TOC_QUERY_FILEPATH := 'xq/metadata.xq';

(:xquery text hook:)
declare variable $max.cons:TEXT_HOOK_XQUERY_FILEPATH := 'xq/text_hook.xq';

(: toc xsl :)
declare variable $max.cons:TOC_XSL_FILENAME := "toc.xsl";

(: document toc xsl :)
declare variable $max.cons:DOCUMENT_TOC_XSL_FILENAME := "document_toc.xsl";

(: nav bar xsl :)
declare variable $max.cons:NAV_BAR_XSL_FILEPATH := "nav_bar.xsl";

(: document title xsl :)
declare variable $max.cons:DOCUMENT_TITLE_XSL_FILEPATH := "document_title.xsl";

(: text xsl :)
declare variable $max.cons:TEXT_HOOK_XSL_FILENAME := "text_hook.xsl";

(: document title xsl :)
declare variable $max.cons:FO_XSL_FILEPATH := "2fo.xsl";


(: html template filename :)
declare variable $max.cons:HTML_TEMPLATE:= "template.html";

(:Project TOC  types:)
declare variable $max.cons:AUTO_TOC := "auto";
declare variable $max.cons:CUSTOM_TOC := "custom";
declare variable $max.cons:STATIC_HTML_TOC := "static";

(:context Key properties:)
declare variable $max.cons:PROJECT_CONTEXT_KEY := "project";
declare variable $max.cons:BASE_URI_CONTEXT_KEY := "baseURI";
declare variable $max.cons:DB_PATH_CONTEXT_KEY := "dbPath";
declare variable $max.cons:ROUTE_ID_CONTEXT_KEY := "routeId";


(:Edition's Footer path:)
declare variable $max.cons:EDITION_FOOTER_PATH := "fragments/footer.frag.html";


(:Default XSL for alignment - automatically executed on aligned routes :)
declare variable $max.cons:ALIGNMENT_XSL := "alignment.xsl";