let buttonParams = [];
let menuFocused = false;
let currentButton = 0;
let buttons = [];
let menuOpened = false;
let menu_length = 0;

// Sound effects
const appendSound = new Audio('https://trickortreatvisualfactory.com/pablo/api/proyects/append.wav');
const scrollSound = new Audio('https://trickortreatvisualfactory.com/pablo/api/proyects/scroll.mp3');
const selectSound = new Audio('https://trickortreatvisualfactory.com/pablo/api/proyects/click_1.wav');

// Set volumes
appendSound.volume = 0.5;
scrollSound.volume = 0.2;
selectSound.volume = 0.2;

// Voice configuration
const spanishVoices = [
    { gender: "male", name: "Nestor", model: "aura-2-nestor-es" },
    { gender: "female", name: "Carina", model: "aura-2-carina-es" },
    { gender: "male", name: "Alvaro", model: "aura-2-alvaro-es" },
    { gender: "female", name: "Diana", model: "aura-2-diana-es" }
];

// TTS Function
async function speakWithDeepgram(text, gender) {
    try {
        const availableVoices = gender ?
            spanishVoices.filter(v => v.gender === gender) :
            spanishVoices;

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
        audio.volume = 0.6;
        audio.play();

        console.log(`Using voice: ${randomVoice.name} (${randomVoice.gender})`);
    } catch (err) {
        console.error("Deepgram TTS failed:", err);
    }
}

// Button selection and UI functions
const selectButton = (id) => {
    currentButton = id;

    // Reset all buttons
    $('.button').removeClass('button-selected');
    $('.button').css({
        'background': '',
        'color': ''
    });
    $('.button .square').css({
        'background-color': '#626262',
        'transform': 'rotate(45deg)'
    });
    $('.button .header').css({
        'color': '#626262',
        'font-weight': '500'
    });
    // Style selected button
    const selectedBtn = $(`#${id}`);
    selectedBtn.addClass('button-selected');
    selectedBtn.css({
        'background': 'rgba(22, 151, 139, 0.1)',
    });
    selectedBtn.find('.square').css({
        'background-color': '#16978B',
        'transform': 'rotate(90deg)'
    });
    selectedBtn.find('.header').css({
        'color': '#16978B',
        'font-weight': '500'
    });

    // Scroll to selected button
    var offset = selectedBtn.position().top;
    $('#buttons').scrollTop(offset);
};

const getButtonRender = (text, id, isDisabled = false) => {
    return `
        <div class="flex items-center gap-2">
                <div class="flex items-center gap-2 button w-full py-3 px-6 bg-black/30 backdrop-blur-md border-b-[0.50px] border-zinc-800/40 flex justify-start items-center transition-all duration-[250ms] ${isDisabled ? "opacity-20" : "hover:bg-black/40"}" id="${id}">
                    <div class="square w-4 h-4 bg-[#626262] transition-all duration-300" style="transform: rotate(45deg);"></div>
                    <div class="header text-[#626262] text-sm font-medium font-['IBM_Plex_Mono'] uppercase">${text}</div>
                </div>
        </div>
    `;
};

const openMenu = (data) => {
    menuOpened = true;
    $("#buttons").html("");
    buttonParams = [];

    // Set dialog text and NPC name
    $("#dialog").html(data.dialog);
    $("#title").html(data.name || 'Diálogo');

    // Play TTS if enabled
    if (data.gender) {
        speakWithDeepgram(data.dialog, data.gender);
    }

    // Process menu items
    let html = "";
    buttons = [];

    data.options.forEach((option, index) => {
        if (typeof option === 'string') {
            // Handle simple string options
            buttons.push(index);
            html += getButtonRender(option, index, false);
        } else if (!option.hidden) {
            // Handle object options (for backward compatibility)
            if (!option.isMenuHeader && !option.disabled) buttons.push(index);

            if (option.isMenuHeader) {
                if (option.header) $("#title").html(option.header);
                return;
            }

            // Use the first element of the array as the button text
            const buttonText = Array.isArray(option) ? option[0] : (option.text || option);
            html += getButtonRender(buttonText, index, option.disabled);

            if (option.params) buttonParams[index] = option.params;
        }
    });

    if (!$("#title").html()) $("#title").html('Diálogo');
    menu_length = buttons[0] == 0 ? buttons.length - 1 : buttons.length;

    if (!menuFocused) $('#container').css('opacity', '.7');
    $('#container').removeClass('onExit').removeClass('hidden');
    $("#buttons").html(html);

    if (buttons.length > 0) {
        selectButton(buttons[0]);
    }

    appendSound.currentTime = 0;
    appendSound.play();
};

const closeMenu = () => {
    $('#container').addClass('onExit');
    menuOpened = false;
    setTimeout(() => {
        if (!menuOpened) {
            $('#container').addClass('hidden');
            menuFocused = false;
        }
    }, 200);
};

const postData = (id) => {
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

    $.post(`https://${GetParentResourceName()}/action`, JSON.stringify({
        action: "option",
        options: buttonParams[id] || id,
        name: $("#title").text()
    }));

    selectSound.currentTime = 0;
    selectSound.play();
    closeMenu();
};

const cancelMenu = () => {
    $.post(`https://${GetParentResourceName()}/action`, JSON.stringify({
        action: "close"
    }));

    appendSound.currentTime = 0;
    appendSound.play();
    closeMenu();
};

const upMenu = () => {
    const currentIndex = buttons.indexOf(currentButton);
    if (currentIndex > 0) {
        selectButton(buttons[currentIndex - 1]);
        checkScroll(buttons[currentIndex - 1]);
    } else {
        selectButton(buttons[buttons.length - 1]);
        checkScroll(buttons[buttons.length - 1]);
    }
    scrollSound.currentTime = 0;
    scrollSound.play();
};

const downMenu = () => {
    const currentIndex = buttons.indexOf(currentButton);
    if (currentIndex < buttons.length - 1) {
        selectButton(buttons[currentIndex + 1]);
        checkScroll(buttons[currentIndex + 1]);
    } else {
        selectButton(buttons[0]);
        checkScroll(buttons[0]);
    }
    scrollSound.currentTime = 0;
    scrollSound.play();
};

const checkScroll = (buttonIndex) => {
    const button = document.getElementById(buttonIndex);
    if (!button) return;

    const container = document.getElementById('buttons');
    const buttonTop = button.offsetTop - container.offsetTop;
    const buttonBottom = buttonTop + button.offsetHeight;

    if (buttonTop < container.scrollTop) {
        container.scrollTop = buttonTop - 10;
    } else if (buttonBottom > container.scrollTop + container.clientHeight) {
        container.scrollTop = buttonBottom - container.clientHeight + 10;
    }
};

// Event Listeners
window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'uiopen') {
        // Format options for the menu
        const menuData = {
            dialog: data.dialog,
            name: data.name,
            gender: data.gender,
            options: data.options.map(option => ({
                header: option[0],
                txt: option[1],
                icon: option[2] || 'fas fa-comment',
                params: option[3] || null,
                disabled: option.disabled || false,
                hidden: option.hidden || false
            }))
        };

        openMenu(menuData);
    } else if (data.action === 'close') {
        closeMenu();
    }
});

document.onkeyup = function (event) {
    if (!menuOpened) return;

    event = event || window.event;
    const key = event.key;

    switch (key) {
        case 'ArrowUp':
            upMenu();
            break;
        case 'ArrowDown':
            downMenu();
            break;
        case 'Enter':
            if (currentButton !== null) {
                postData(currentButton);
            }
            break;
        case 'Escape':
            cancelMenu();
            break;
    }
};

// Hover effects
$(document).on('mouseenter', '.button:not(.button-selected)', function () {
    if (menuFocused) return;
    const id = $(this).attr('id');
    if (id) {
        selectButton(id);
        scrollSound.currentTime = 0;
        scrollSound.play();
    }
});

$(document).on('click', '.button', function () {
    if ($(this).hasClass('button-selected')) {
        postData(currentButton);
    } else {
        const id = $(this).attr('id');
        if (id) {
            selectButton(id);
            scrollSound.currentTime = 0;
            scrollSound.play();
        }
    }
});

// Mouse wheel support for scrolling
$('#buttons').on('wheel', function (e) {
    if (e.originalEvent.deltaY < 0) {
        // Scrolling up
        $(this).scrollTop($(this).scrollTop() - 30);
    } else {
        // Scrolling down
        $(this).scrollTop($(this).scrollTop() + 30);
    }
});

// Focus handling
$('#container').on('mouseenter', function () {
    menuFocused = true;
    $(this).css('opacity', '1');
});

$('#container').on('mouseleave', function () {
    menuFocused = false;
    $(this).css('opacity', '0.7');
});

// Initialize with debug mode
$(document).ready(function () {
    const isDebugMode = window.location.search.includes('debug=1');

    if (isDebugMode) {
        $('#debug-background').css('display', 'block');
        $('#game-view').css('display', 'none');

        openMenu({
            dialog: '¡Hola! ¿En qué puedo ayudarte hoy?',
            name: 'Juan Pérez',
            gender: 'male',
            options: [
                'Ver cuenta del banco',
                'Pegarle una patada al NPC',
                'Preguntar por misiones',
                'Comerciar',
                'Robar',
                'Salir'
            ]
        });
    } else {
        $('#debug-background').css('display', 'none');
        $('#game-view').css('display', 'block');
    }
});
