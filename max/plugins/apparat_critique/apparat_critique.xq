xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $baseURI external;
declare variable $dbPath external;
declare variable $project external;
declare variable $doc external;
declare variable $id external;

<div class="apparat-witnesses">
    <h3>Apparat critique</h3>
    <ul>
        <li class="witness_item" id="lem_item">
            <input onchange='apparat.showWitness("lem")'
            type='radio'
            name='witnesses'
            class='witness'
            checked="checked"
            aria-label="lem"/><span class='witness_label'>Version par défaut</span>
        </li>
        {
            for $w in doc($dbPath ||'/'||$doc)//tei:listWit//tei:witness[@xml:id]
                let $idAsText := string($w/@xml:id)
                return <li>
                        <input onchange='apparat.showWitness("{$idAsText}")'
                               type='radio'
                               name='witnesses'
                               class='witness'
                               aria-label="{$idAsText}"/>Témoin {$idAsText}
                        </li>
        }
    </ul>
</div>