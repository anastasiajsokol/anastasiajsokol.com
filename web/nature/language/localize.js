const localization_maps = [
    "language/base.json"
];

function localize_from_source(source, language){
    fetch(source).then(res => res.json()).then(res => {
        // make sure the language code exists
        if(!res[language]){
            console.warn(`Language source [${source}] does not support requested language [${language}]`);
            return;
        }

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
    if(language != 'en' && language != 'ru' && language != 'de'){
        console.error(`Invalid language code passed to localize [${language}]`);
        return;
    }
    
    const days_till_expires = 10;
    const date = new Date(Date.now() + days_till_expires * 24 * 60 * 60 * 1000);
    
    document.cookie = `language=${language}; expires=${date.toUTCString()};`;

    for(const source of localization_maps){
        localize_from_source(source, language);
    }
}

// handle preload language requests

const query_string = window.location.search;
const url_parameters = new URLSearchParams(query_string);

const language_cookie = document.cookie.split("; ").find((row) => row.startsWith("language="))?.split('=')[1];

if(url_parameters.has("language") || language_cookie){
    window.addEventListener("load", _ => {
        localize(url_parameters.get("language") ?? language_cookie);
    });
}