const localization_maps = [
    "language/base.json"
];

function localize(source, language){
    fetch(source).then(res => res.json()).then(res => {
        for(const [id, value] of Object.entries(res[language])){
            document.getElementById(id).innerHTML = value;
        }
    }).catch(err => console.error(`Unable to load language translation source [${source}] because [${err}]`));
}