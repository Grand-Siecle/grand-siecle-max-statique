import module namespace max.i18n = "pddn/max/i18n" at "../../rxq/i18n.xqm";

declare variable $baseURI external;
declare variable $dbPath external;
declare variable $project external;
declare variable $doc external;
declare variable $id external;

let $locale := max.i18n:getLang($project)

return 
 if($id='eadheader' or $id='archdesc')
    then ()
    else
<nav class="article_actions">
	<ul>
		<li>
			<label>
				<input type="checkbox" id="basket_toggle"/>
				{max.i18n:getText($project,'label.dansvotre',$locale)||' '}
				<a href="{$baseURI}{$project}/porte-documents.html">
					{max.i18n:getText($project,'label.porte-documents',$locale)}
				</a>
			</label>
		</li>
	</ul>
</nav>