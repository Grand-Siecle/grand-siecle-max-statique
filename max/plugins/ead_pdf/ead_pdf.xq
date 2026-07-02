declare variable $id external;

(:hides pdf export in eadheader or archdesc consult context :)
    if($id='eadheader' or $id='archdesc')
    then ()
    else
        <div class="ead2pdf">
            <a role="button" title="Export pdf" target="_blank" href="./ead/{$id}.pdf">
                &#8682;<span class="texte">PDF</span>
            </a>
        </div>

