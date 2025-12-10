const DEBUG = true;

let options = {};

var appendSound = new Audio('https://trickortreatvisualfactory.com/pablo/api/proyects/append.wav');
var scrollSound = new Audio('https://trickortreatvisualfactory.com/pablo/api/proyects/scroll.mp3');
var selectSound = new Audio('https://trickortreatvisualfactory.com/pablo/api/proyects/click_1.wav');

appendSound.volume = 0.5;
scrollSound.volume = 0.2;
selectSound.volume = 0.15;

const spanishVoices = [
    {
        gender: "male",
        name: "Nestor",
        model: "aura-2-nestor-es"
    },
    {
        gender: "female",
        name: "Carina",
        model: "aura-2-carina-es"
    },
    {
        gender: "male",
        name: "Alvaro",
        model: "aura-2-alvaro-es"
    },
    {
        gender: "female",
        name: "Diana",
        model: "aura-2-diana-es"
    }
];

async function speakWithDeepgram(text, gender) {
    try {
        const availableVoices = spanishVoices.filter(v => v.gender === gender);
        if (availableVoices.length === 0) {
            console.warn("No voices available for gender:", gender);
            return;
        }

        const randomVoice = availableVoices[Math.floor(Math.random() * availableVoices.length)];

        const response = await fetch(`https://api.deepgram.com/v1/speak?model=${randomVoice.model}`, {
            method: "POST",
            headers: {
                "Authorization": "Token 06970596049b8c1599d0e36e4cb61b9cd68d1a7f",
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ text })
        });

        if (!response.ok) {
            console.error("Deepgram error:", response.status, await response.text());
            return;
        }

        const audioBuffer = await response.arrayBuffer();
        const blob = new Blob([audioBuffer], { type: "audio/wav" });
        const url = URL.createObjectURL(blob);
        const audio = new Audio(url);
        audio.volume = 0.4;
        audio.play();

        console.log(`Usando voz: ${randomVoice.name} (${randomVoice.gender})`);
    } catch (err) {
        console.error("Deepgram TTS failed:", err);
    }
}

if (DEBUG) {
    $('body').show();
    $('#dialog').html('Este es un texto de prueba para ver cómo se ve el diálogo en el sistema. Puedes cambiar el contenido aquí para probar diferentes longitudes de texto.');
    $('#name').html('<small>Juan</small> Pérez');
    $('#option0').show().html('Opción 1: Hablar con el NPC');
    $('#option1').show().html('Opción 2: Preguntar sobre misiones');
    $('#option2').show().html('Opción 3: Ver inventario');
    $('#option3').show().html('Opción 4: Comerciar');
}

window.addEventListener('message', function(event) {
    const item = event.data;

    if (event.data.action === 'uiopen') {
        appendSound.currentTime = 0;
        appendSound.play();

        options = item.options;
        $('#dialog').html(item.dialog);
        $('#name').html(item.name);
        speakWithDeepgram(item.dialog, item.gender);

        const numoptions = Math.min(item.options.length, 5);
        $(".button-close").css("animation-delay");
        for (let i = 0; i < 6; i++) {
            const $option = $(`#option${i}`);
            if (i < numoptions) {
                $option.show().html(item.options[i][0]);
                $option.off("click").on('click', function() {
                    $.post('https://RevoDialogsNPC/action', JSON.stringify({
                        action: "option",
                        options: options[i],    
                        name: item.name,
                    }));
                    $(".menu").removeClass("open").addClass("close");
                    setTimeout(() => $('body').fadeOut(), 200);
                });
            } else {
                $option.hide();
            }
        }
        $(".menu").removeClass("close").addClass("open");
        $('body').fadeIn();
    }
});

$(document).on('click', '.button, .esc_button', function () {
    selectSound.currentTime = 0;
    selectSound.play();
});

$(document).on('mouseenter', '.button, .esc_button', function () {
    scrollSound.currentTime = 0;
    scrollSound.play();
});

$(document).on('click', ".esc_button", function() {
    $(".menu").removeClass("open").addClass("close");
    setTimeout(() => $('body').fadeOut(), 200);
    $.post('https://RevoDialogsNPC/action', JSON.stringify({
        action: "close",
    }));
});

window.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
        $(".menu").removeClass("open").addClass("close");
        setTimeout(() => $('body').fadeOut(), 200);
        $.post('https://RevoDialogsNPC/action', JSON.stringify({
            action: "close",
        }));
    }
});
