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
            return;
        }

        const audioBuffer = await response.arrayBuffer();
        const blob = new Blob([audioBuffer], { type: "audio/wav" });
        const url = URL.createObjectURL(blob);
        const audio = new Audio(url);
        audio.volume = 0.4;
        audio.play();
    } catch (err) {
    }
}

window.addEventListener('message', function (event) {
    const item = event.data;

    if (event.data.action === 'uiopen') {
        appendSound.currentTime = 0;
        appendSound.play();

        $('#game-view').addClass('active');

        options = item.options;
        $('#dialog').html(item.dialog);
        $('#title').html(item.name);

        if (item.gender) {
            speakWithDeepgram(item.dialog, item.gender);
        }

        const numoptions = Math.min(item.options.length, 6);
        let buttonsHTML = '';

        for (let i = 0; i < numoptions; i++) {
            const optionText = item.options[i][0];
            buttonsHTML += `
                <div class="flex items-center gap-2 button w-full py-3 px-6 bg-black/30 backdrop-blur-md border-b-[0.50px] border-zinc-800/40 flex justify-start items-center transition-all duration-[250ms] hover:bg-black/40 cursor-pointer" id="option${i}">
                    <div class="square w-4 h-4 bg-[#626262] transition-all duration-300" style="transform: rotate(45deg);"></div>
                    <div class="header text-[#626262] text-sm font-medium font-['IBM_Plex_Mono'] uppercase">${optionText}</div>
                </div>
            `;
        }

        $("#buttons").html(buttonsHTML);

        for (let i = 0; i < numoptions; i++) {
            $(`#option${i}`).off("click").on('click', function () {
                selectSound.currentTime = 0;
                selectSound.play();

                const selectIcon = $('.select-option');
                if (selectIcon.length) {
                    selectIcon.css({
                        'background': '#16978B',
                        'border-color': '#16978B'
                    });

                    setTimeout(() => {
                        selectIcon.css({
                            'background': '',
                            'border-color': ''
                        });
                    }, 250);
                }

                $.post('https://RevoDialogsNPC/action', JSON.stringify({
                    action: "option",
                    options: options[i],
                    name: item.name,
                }));

                $('#container').addClass('onExit');
                setTimeout(() => {
                    $('#container').addClass('hidden');
                    $('body').fadeOut();
                }, 400);
                setTimeout(() => {
                    $('#game-view').removeClass('active');
                }, 800);
            });
        }

        $('body').fadeIn();
        $('#container').removeClass('onExit').removeClass('hidden');
    }
});

$(document).on('mouseenter', '.button', function () {
    scrollSound.currentTime = 0;
    scrollSound.play();

    $('.button .square').css({
        'background-color': '#626262',
        'transform': 'rotate(45deg)'
    });
    $('.button .header').css({
        'color': '#626262'
    });

    $(this).find('.square').css({
        'background-color': '#16978B',
        'transform': 'rotate(90deg)'
    });
    $(this).find('.header').css({
        'color': '#16978B'
    });

    const scrollIcon = $('.scroll-option');
    if (scrollIcon.length) {
        scrollIcon.css({
            'background': '#16978B',
            'border-color': '#16978B'
        });

        setTimeout(() => {
            scrollIcon.css({
                'background': '',
                'border-color': ''
            });
        }, 250);
    }
});

window.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
        $('#container').addClass('onExit');
        setTimeout(() => {
            $('#container').addClass('hidden');
            $('body').fadeOut();
        }, 400);
        setTimeout(() => {
            $('#game-view').removeClass('active');
        }, 800);
        $.post('https://RevoDialogsNPC/action', JSON.stringify({
            action: "close",
        }));
    }
});
