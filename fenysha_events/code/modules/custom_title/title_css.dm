#define CUSTOM_TITLE_HTML {"
    <html>
        <head>
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
            <style type='text/css'>
                @font-face {
                    font-family: "Fixedsys";
                    src: url("FixedsysExcelsior3.01Regular.ttf");
                }
                body, html {
                    margin: 0;
                    overflow: hidden;
                    text-align: center;
                    background-color: black;
                    image-rendering: pixelated;
                    text-rendering: geometricPrecision;
                    -ms-user-select: none;
                    cursor: default;
                    width: 100%;
                    height: 100%;
                }

                img {
                    border-style: none;
                }

                .bg {
                    position: absolute;
                    width: auto;
                    height: 100vmin;
                    min-width: 100vmin;
                    min-height: 100vmin;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    z-index: 0;
                    transition: transform 0.1s ease-out;
                }

                .shell_container {
                    position: absolute;
                    width: 100%;
                    height: 100%;
                    top: 0;
                    left: 0;
                    pointer-events: none;
                    z-index: 0;
                    overflow: hidden;
                }

                .shell_layer {
                    position: absolute;
                    width: 100%;
                    height: 100%;
                    top: 0;
                    left: 0;
                    pointer-events: none;
                    overflow: hidden;
                    transition: transform 0.12s ease-out;
                }

                .shell_layer_back  { z-index: 1; }
                .shell_layer_mid   { z-index: 2; }
                .shell_layer_front { z-index: 3; }

                .shell {
                    position: absolute;
                    top: 0;
                    background-size: contain;
                    background-position: center;
                    background-repeat: no-repeat;
                    animation-timing-function: linear;
                    animation-fill-mode: forwards;
                    will-change: transform;
                }

                .shell_back {
                    width: 4vmin;
                    height: 4vmin;
                    filter: blur(2px);
                }

                .shell_mid {
                    width: 8vmin;
                    height: 8vmin;
                }

                .shell_front {
                    width: 14vmin;
                    height: 14vmin;
                }

                @keyframes shell_fall {
                    0%   { transform: translate(0vmin, -20vh) rotate(0deg); }
                    100% { transform: translate(var(--drift-x, 0vmin), 120vh) rotate(var(--rot, 720deg)); }
                }

                .cache_helper {
                    position: absolute;
                    width: 1px;
                    height: 1px;
                    top: -10px;
                    left: -10px;
                    opacity: 0;
                    pointer-events: none;
                }

                /* загрузчик */
                .container_loading {
                    display: flex;
                    flex-direction: row;
                    align-items: center;
                    justify-content: flex-end;
                    gap: 15px;
                    position: absolute;
                    bottom: 40px;
                    right: 40px;
                }

                .progress_ring {
                    transform: rotate(-90deg);
                    flex-shrink: 0;
                }

                .progress_ring_circle {
                    transition: stroke-dashoffset 0.15s ease-out;
                }

                .terminal_text {
                    text-align: right;
                    font-family: "Fixedsys", monospace;
                    font-size: 1.8vmin;
                    color: #f0d30b;
                }

                /* блок с кнопками */
                .container_nav {
                    position: absolute;
                    box-sizing: border-box;
                    width: 45vmin;
                    top: 50%;
                    right: 5vmin;
                    transform: translateY(-50%);
                    z-index: 4;
                    padding: 0;
                    background: transparent;
                    border: none;
                    box-shadow: none;
                    transition: transform 0.1s ease-out;
                }

                .container_nav hr {
                    height: 1px;
                    background-color: rgba(205, 222, 238, 0.3);
                    border: none;
                    margin: 1.5vmin 0;
                }

                .character_display {
                    margin-top: 2vmin;
                    font-family: "Fixedsys";
                    font-size: 2vmin;
                    color: #88aabb;
                                        text-align: right;
                    text-shadow: 1px 1px 2px black;
                }

                .character_name {
                    font-size: 3vmin;
                    color: #ffffff;
                    font-weight: bold;
                }

                /* Кнопки  */
                .menu_button {
                    display: block;
                    box-sizing: border-box;
                    font-family: "Fixedsys";
                    font-weight: lighter;
                    text-decoration: none;
                    font-size: 3.5vmin;
                    text-shadow: 2px 2px 4px black;
                    line-height: 4.5vmin;
                    width: 100%;
                    text-align: right;
                    color: #cde;
                    background: transparent;
                    border: none;
                    padding: 0;
                    letter-spacing: 1px;
                    cursor: pointer;
                    white-space: nowrap;
                    overflow: hidden;
                    transition: color 0.2s, transform 0.1s;
                }

                .menu_button:hover {
                    color: yellow;
                    transform: scale(1.05);
                }

                .menu_button:active {
                    color: #ffaa00;
                    transform: scale(0.98);
                }

                .menu_button:hover::before {
                    content: "☞ ";
                }

                .menu_button:active::before {
                    content: "☛ ";
                }

                .container_notice {
                    position: absolute;
                    box-sizing: border-box;
                    width: auto;
                    top: 10vmin;
                    left: 50%;
                    transform: translateX(-50%);
                    z-index: 4;
                }

                .menu_notice {
                    font-family: "Fixedsys";
                    color: red;
                    text-shadow: 1px 1px 2px black;
                    font-size: 3vmin;
                }

                .unchecked { color: #F44; }
                .checked { color: #4F4; }
            </style>
        </head>
        <body>
            "}
