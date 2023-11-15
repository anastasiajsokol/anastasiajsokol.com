const localization_maps = [
    "language/base.json"
];

function localize_from_source(source, language){
    fetch(source).then(res => res.json()).then(res => {
        // inner html
        for(const [id, value] of Object.entries(res[language])){
            for(const element of document.querySelectorAll(`[langtag='${id}']`)){
                element.innerHTML = value;
            }
        }

        // placeholders
        for(const [id, value] of Object.entries(res[language])){
            for(const element of document.querySelectorAll(`[langplaceholder='${id}']`)){
                element.placeholder = value;
            }
        }
    }).catch(err => console.error(`Unable to load language translation source [${source}] because [${err}]`));
}

function localize(language){
    for(const source of localization_maps){
        localize_from_source(source, language);
    }
}