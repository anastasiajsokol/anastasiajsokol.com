import * as THREE from 'three';

window.addEventListener("load", async _ => {
    // setup threejs
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);

    const renderer = new THREE.WebGLRenderer({
        canvas: document.getElementById("background")
    });

    renderer.setSize(window.innerWidth, window.innerHeight);

    // handle resize
    window.addEventListener("resize", _ => {
        renderer.setSize(window.innerWidth, window.innerHeight);
        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
    });

    // initialize state
    {
        const geometry = new THREE.PlaneGeometry(1000, 1000, 1000, 1000);
        
        const material = new THREE.ShaderMaterial({
            fragmentShader: await fetch("/nature/art/fragment.glsl").then(res => res.text()),
            vertexShader: await fetch("/nature/art/vertex.glsl").then(res => res.text())
        });

        var plane = new THREE.Mesh(geometry, material);
        
        plane.rotation.x = -Math.PI / 2;

        scene.add(plane);
    }

    camera.position.z = 5;
    camera.position.y = 5;

    // main render loop
    const time = {
        time: 0,
        dt: 0
    };
    
    function render(timestamp){
        time.dt = (timestamp - time.time) * 0.001;
        time.time = timestamp;

        if(time.dt < 0.1){ // require at least 10 fps to update world state
            
        }
        
        requestAnimationFrame(render);
        renderer.render(scene, camera);
    } requestAnimationFrame(render);
});