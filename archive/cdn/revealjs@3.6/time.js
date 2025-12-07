function create_timer_element(){
    const span = document.createElement("span");

    span.style.position = "fixed";
    span.style.right = "1rem";
    span.style.top = "1rem";

    span.style.fontSize = "1.5rem";

    span.innerText = "00:00";

    return span;
}

function update(timer, time){
    timer.innerText = `${String(Math.floor(time / 60)).padStart(2, "0")}:${String(Math.floor(time % 60)).padStart(2, "0")}`;
}

window.addEventListener("load", _ => {
    const reveal = document.querySelector(".reveal");

    if(!reveal){
        console.error("time.js : could not find the .reveal element");
    }

    let time = reveal.getAttribute("time");

    if(!time){
        console.warn("time.js : the .reveal element does not have a time attr");
    }

    if(time[time.length - 1] != 's'){
        console.error("the time", time, "must be a number followed by 's'");
    }

    time = Number.parseInt(time.substring(0, time.length - 1));

    const timer = create_timer_element();
    document.body.appendChild(timer);
    update(timer, time);   
    
    let started = false;

    Reveal.addEventListener("slidechanged", _ => {
        if(!started){
            setInterval(_ => {
                if(time <= 0){
                    return;
                }

                time -= 1;
                update(timer, time);
            }, 1000);

            started = true;
        }
    });
});