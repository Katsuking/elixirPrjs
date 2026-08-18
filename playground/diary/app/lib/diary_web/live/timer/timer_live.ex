defmodule DiaryWeb.TimerLive do
  @moduledoc """
  LiveView component for the Timer and Stopwatch page.
  Delegates execution to the TimerHook client-side JavaScript for precise, low-latency counting.
  """
  use DiaryWeb, :live_view
  use Gettext, backend: DiaryWeb.Gettext

  @impl true
  def mount(_params, session, socket) do
    # Fetch locale to translate page titles if needed
    locale = session["locale"] || "en"
    Gettext.put_locale(DiaryWeb.Gettext, locale)

    {:ok,
     socket
     |> assign(active_tab: "timer") # Set active tab for layout navigation highlight
     |> assign(locale: locale)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab="timer">
      <div class="max-w-md mx-auto bg-white dark:bg-zinc-900 rounded-3xl shadow-xl border border-slate-100 dark:border-zinc-850 overflow-hidden transition-all duration-300">
        
        <!-- Container with TimerHook. phx-update="ignore" guarantees no DOM resets during operations.
             Tabs are placed inside the container so they are protected from DOM patches. -->
        <div id="timer-hook-container" phx-hook=".TimerHook" phx-update="ignore" class="w-full">
          
          <!-- Tab selector for mode (Timer vs Stopwatch) -->
          <div id="timer-tabs" class="flex border-b border-slate-100 dark:border-zinc-800 bg-slate-50/50 dark:bg-zinc-900/50">
            <button
              id="tab-timer"
              class="flex-1 py-4 text-xs font-black uppercase tracking-wider transition-all duration-200 cursor-pointer flex items-center justify-center gap-2 border-b-2 border-zinc-850 dark:border-zinc-100 text-zinc-900 dark:text-zinc-100 bg-white dark:bg-zinc-900"
            >
              <.icon name="hero-clock" class="size-4" />
              {gettext("Timer")}
            </button>
            <button
              id="tab-stopwatch"
              class="flex-1 py-4 text-xs font-black uppercase tracking-wider transition-all duration-200 cursor-pointer flex items-center justify-center gap-2 border-b-2 border-transparent text-slate-400 hover:text-slate-600 dark:hover:text-zinc-300"
            >
              <.icon name="hero-stopwatch" class="size-4" />
              {gettext("Stopwatch")}
            </button>
          </div>

          <!-- Content Wrapper -->
          <div class="p-8 space-y-8 flex flex-col items-center">
            
            <!-- --- TIMER MODE VIEW --- -->
            <div id="timer-view" class="w-full flex flex-col items-center space-y-8">
              <!-- Circular Progress SVG for visual countdown countdown -->
              <div class="relative w-64 h-64 flex items-center justify-center">
                <svg class="w-full h-full transform -rotate-90">
                  <!-- Outer Track -->
                  <circle
                    cx="128"
                    cy="128"
                    r="110"
                    class="stroke-slate-100 dark:stroke-zinc-800 fill-none"
                    stroke-width="8"
                  />
                  <!-- Inner Active Bar -->
                  <circle
                    id="timer-progress-ring"
                    cx="128"
                    cy="128"
                    r="110"
                    class="stroke-zinc-800 dark:stroke-zinc-100 fill-none transition-all duration-100 ease-linear"
                    stroke-width="8"
                    stroke-dasharray="691.15"
                    stroke-dashoffset="0"
                    stroke-linecap="round"
                  />
                </svg>
                <!-- Center Text displaying current time -->
                <div class="absolute flex flex-col items-center">
                  <span id="timer-display" class="text-5xl font-black tabular-nums tracking-tighter text-zinc-800 dark:text-zinc-100">
                    03:00
                  </span>
                  <span id="timer-status-text" class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1">
                    Ready
                  </span>
                </div>
              </div>

              <!-- Custom Quick Time Selectors for workout intervals -->
              <div id="timer-presets" class="w-full grid grid-cols-5 gap-2">
                <button data-seconds="30" class="py-2.5 bg-slate-50 hover:bg-slate-100 dark:bg-zinc-800/40 dark:hover:bg-zinc-800 border border-slate-100 dark:border-zinc-800/60 rounded-xl text-xs font-black text-slate-500 dark:text-zinc-400 hover:text-zinc-850 dark:hover:text-zinc-200 transition-colors cursor-pointer">+30s</button>
                <button data-seconds="60" class="py-2.5 bg-slate-50 hover:bg-slate-100 dark:bg-zinc-800/40 dark:hover:bg-zinc-800 border border-slate-100 dark:border-zinc-800/60 rounded-xl text-xs font-black text-slate-500 dark:text-zinc-400 hover:text-zinc-850 dark:hover:text-zinc-200 transition-colors cursor-pointer">+1m</button>
                <button data-seconds="120" class="py-2.5 bg-slate-50 hover:bg-slate-100 dark:bg-zinc-800/40 dark:hover:bg-zinc-800 border border-slate-100 dark:border-zinc-800/60 rounded-xl text-xs font-black text-slate-500 dark:text-zinc-400 hover:text-zinc-850 dark:hover:text-zinc-200 transition-colors cursor-pointer">+2m</button>
                <button data-seconds="180" class="py-2.5 bg-slate-50 hover:bg-slate-100 dark:bg-zinc-800/40 dark:hover:bg-zinc-800 border border-slate-100 dark:border-zinc-800/60 rounded-xl text-xs font-black text-slate-500 dark:text-zinc-400 hover:text-zinc-850 dark:hover:text-zinc-200 transition-colors cursor-pointer">+3m</button>
                <button data-seconds="300" class="py-2.5 bg-slate-50 hover:bg-slate-100 dark:bg-zinc-800/40 dark:hover:bg-zinc-800 border border-slate-100 dark:border-zinc-800/60 rounded-xl text-xs font-black text-slate-500 dark:text-zinc-400 hover:text-zinc-850 dark:hover:text-zinc-200 transition-colors cursor-pointer">+5m</button>
              </div>

              <!-- Manual Adjustments (+/-) -->
              <div id="timer-adjusters" class="flex items-center gap-6 text-slate-500">
                <div class="flex items-center gap-2">
                  <span class="text-[10px] font-black uppercase tracking-wider">{gettext("Min")}</span>
                  <button id="btn-dec-min" class="p-2 rounded-lg bg-slate-50 hover:bg-slate-100 dark:bg-zinc-800/40 dark:hover:bg-zinc-800 border border-slate-100 dark:border-zinc-800/60 cursor-pointer">
                    <.icon name="hero-minus" class="size-3.5" />
                  </button>
                  <button id="btn-inc-min" class="p-2 rounded-lg bg-slate-50 hover:bg-slate-100 dark:bg-zinc-800/40 dark:hover:bg-zinc-800 border border-slate-100 dark:border-zinc-800/60 cursor-pointer">
                    <.icon name="hero-plus" class="size-3.5" />
                  </button>
                </div>
                <div class="flex items-center gap-2">
                  <span class="text-[10px] font-black uppercase tracking-wider">{gettext("Sec")}</span>
                  <button id="btn-dec-sec" class="p-2 rounded-lg bg-slate-50 hover:bg-slate-100 dark:bg-zinc-800/40 dark:hover:bg-zinc-800 border border-slate-100 dark:border-zinc-800/60 cursor-pointer">
                    <.icon name="hero-minus" class="size-3.5" />
                  </button>
                  <button id="btn-inc-sec" class="p-2 rounded-lg bg-slate-50 hover:bg-slate-100 dark:bg-zinc-800/40 dark:hover:bg-zinc-800 border border-slate-100 dark:border-zinc-800/60 cursor-pointer">
                    <.icon name="hero-plus" class="size-3.5" />
                  </button>
                </div>
              </div>

              <!-- Start / Pause / Reset Controls -->
              <div class="flex items-center justify-center gap-4 w-full">
                <button
                  id="btn-timer-reset"
                  class="flex-1 py-3.5 border border-zinc-200 dark:border-zinc-800 text-slate-600 dark:text-zinc-400 font-extrabold rounded-2xl hover:bg-slate-50 dark:hover:bg-zinc-850 hover:text-zinc-800 dark:hover:text-zinc-100 transition-colors duration-200 cursor-pointer text-sm"
                >
                  Reset
                </button>
                <button
                  id="btn-timer-start-pause"
                  class="flex-[2] py-3.5 bg-zinc-800 hover:bg-zinc-900 text-white font-extrabold rounded-2xl shadow-md transition-all duration-200 cursor-pointer text-sm flex items-center justify-center gap-2"
                >
                  <span id="icon-timer-play-pause">
                    <.icon name="hero-play" class="size-4" />
                  </span>
                  <span id="lbl-timer-start-pause">Start</span>
                </button>
              </div>
            </div>

            <!-- --- STOPWATCH MODE VIEW --- -->
            <div id="stopwatch-view" class="w-full hidden flex flex-col items-center space-y-8">
              <!-- Stopwatch numerical display -->
              <div class="w-full py-12 flex flex-col items-center bg-slate-50/40 dark:bg-zinc-800/10 border border-slate-100/60 dark:border-zinc-850 rounded-3xl">
                <span id="stopwatch-display" class="text-6xl font-black tabular-nums tracking-tighter text-zinc-800 dark:text-zinc-100">
                  00:00.00
                </span>
                <span id="stopwatch-status-text" class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-2">
                  Stopwatch
                </span>
              </div>

              <!-- Controls (Reset / Lap and Start / Pause) -->
              <div class="flex items-center justify-center gap-4 w-full">
                <button
                  id="btn-stopwatch-reset-lap"
                  class="flex-1 py-3.5 border border-zinc-200 dark:border-zinc-800 text-slate-600 dark:text-zinc-400 font-extrabold rounded-2xl hover:bg-slate-50 dark:hover:bg-zinc-850 hover:text-zinc-800 dark:hover:text-zinc-100 transition-colors duration-200 cursor-pointer text-sm"
                >
                  Reset
                </button>
                <button
                  id="btn-stopwatch-start-pause"
                  class="flex-[2] py-3.5 bg-zinc-800 hover:bg-zinc-900 text-white font-extrabold rounded-2xl shadow-md transition-all duration-200 cursor-pointer text-sm flex items-center justify-center gap-2"
                >
                  <span id="icon-stopwatch-play-pause">
                    <.icon name="hero-play" class="size-4" />
                  </span>
                  <span id="lbl-stopwatch-start-pause">Start</span>
                </button>
              </div>

              <!-- Lap Times Container -->
              <div id="stopwatch-laps-container" class="w-full hidden space-y-3.5">
                <h3 class="text-xs font-bold text-slate-400 dark:text-zinc-400 uppercase tracking-widest">
                  {gettext("Lap Times")}
                </h3>
                <div id="stopwatch-laps-list" class="max-h-48 overflow-y-auto space-y-2 pr-1 divide-y divide-slate-100 dark:divide-zinc-850">
                  <!-- Rendered dynamically by javascript -->
                </div>
              </div>
            </div>

          </div>

        </div>
      </div>
    </Layouts.app>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".TimerHook">
      export default {
        mounted() {
          this.initTabs();
          this.initStopwatch();
          this.initTimer();
        },

        destroyed() {
          if (this.stopwatchInterval) clearInterval(this.stopwatchInterval);
          if (this.timerInterval) clearInterval(this.timerInterval);
        },

        initTabs() {
          const tabTimer = document.getElementById("tab-timer");
          const tabStopwatch = document.getElementById("tab-stopwatch");
          const timerView = document.getElementById("timer-view");
          const stopwatchView = document.getElementById("stopwatch-view");

          if (!tabTimer || !tabStopwatch) return;

          const selectTab = (mode) => {
            if (mode === "timer") {
              tabTimer.classList.add("border-zinc-850", "dark:border-zinc-100", "text-zinc-900", "dark:text-zinc-100", "bg-white", "dark:bg-zinc-900");
              tabTimer.classList.remove("border-transparent", "text-slate-400");

              tabStopwatch.classList.remove("border-zinc-850", "dark:border-zinc-100", "text-zinc-900", "dark:text-zinc-100", "bg-white", "dark:bg-zinc-900");
              tabStopwatch.classList.add("border-transparent", "text-slate-400");

              timerView.classList.remove("hidden");
              stopwatchView.classList.add("hidden");
            } else {
              tabStopwatch.classList.add("border-zinc-850", "dark:border-zinc-100", "text-zinc-900", "dark:text-zinc-100", "bg-white", "dark:bg-zinc-900");
              tabStopwatch.classList.remove("border-transparent", "text-slate-400");

              tabTimer.classList.remove("border-zinc-850", "dark:border-zinc-100", "text-zinc-900", "dark:text-zinc-100", "bg-white", "dark:bg-zinc-900");
              tabTimer.classList.add("border-transparent", "text-slate-400");

              stopwatchView.classList.remove("hidden");
              timerView.classList.add("hidden");
            }
          };

          tabTimer.addEventListener("click", () => selectTab("timer"));
          tabStopwatch.addEventListener("click", () => selectTab("stopwatch"));
        },

        initStopwatch() {
          const display = document.getElementById("stopwatch-display");
          const btnStartPause = document.getElementById("btn-stopwatch-start-pause");
          const btnResetLap = document.getElementById("btn-stopwatch-reset-lap");
          const lapsContainer = document.getElementById("stopwatch-laps-container");
          const lapsList = document.getElementById("stopwatch-laps-list");
          const iconSpan = document.getElementById("icon-stopwatch-play-pause");
          const lblSpan = document.getElementById("lbl-stopwatch-start-pause");
          const statusText = document.getElementById("stopwatch-status-text");

          let running = false;
          let startTime = 0;
          let elapsed = 0;
          this.stopwatchInterval = null;
          let laps = [];

          const format = (ms) => {
            const pad = (num, size = 2) => String(num).padStart(size, '0');
            const min = Math.floor(ms / 60000);
            const sec = Math.floor((ms % 60000) / 1000);
            const centi = Math.floor((ms % 1000) / 10);
            return `${pad(min)}:${pad(sec)}.${pad(centi)}`;
          };

          const updateDisplay = () => {
            display.textContent = format(elapsed + (running ? (Date.now() - startTime) : 0));
          };

          const renderLaps = () => {
            if (laps.length === 0) {
              lapsContainer.classList.add("hidden");
              lapsList.innerHTML = "";
              return;
            }
            lapsContainer.classList.remove("hidden");
            lapsList.innerHTML = laps.map((lap, index) => `
              <div class="flex items-center justify-between py-2 text-xs font-bold text-slate-500 dark:text-zinc-400">
                <span>Lap ${laps.length - index}</span>
                <span class="tabular-nums font-black text-zinc-800 dark:text-zinc-100">${format(lap)}</span>
              </div>
            `).join("");
          };

          const start = () => {
            running = true;
            startTime = Date.now();
            statusText.textContent = "Running";
            statusText.classList.add("text-emerald-500", "dark:text-emerald-400");
            statusText.classList.remove("text-slate-400");

            iconSpan.innerHTML = '<span class="hero-pause size-4"></span>';
            lblSpan.textContent = "Pause";
            btnResetLap.textContent = "Lap";

            this.stopwatchInterval = setInterval(() => {
              updateDisplay();
            }, 10);
          };

          const pause = () => {
            running = false;
            elapsed += Date.now() - startTime;
            clearInterval(this.stopwatchInterval);
            statusText.textContent = "Paused";
            statusText.classList.remove("text-emerald-500", "dark:text-emerald-400");
            statusText.classList.add("text-slate-400");

            iconSpan.innerHTML = '<span class="hero-play size-4"></span>';
            lblSpan.textContent = "Start";
            btnResetLap.textContent = "Reset";
          };

          const reset = () => {
            running = false;
            elapsed = 0;
            laps = [];
            clearInterval(this.stopwatchInterval);
            statusText.textContent = "Stopwatch";
            statusText.classList.remove("text-emerald-500", "dark:text-emerald-400");
            statusText.classList.add("text-slate-400");

            iconSpan.innerHTML = '<span class="hero-play size-4"></span>';
            lblSpan.textContent = "Start";
            btnResetLap.textContent = "Reset";
            updateDisplay();
            renderLaps();
          };

          const recordLap = () => {
            const current = elapsed + (running ? (Date.now() - startTime) : 0);
            laps.unshift(current);
            renderLaps();
          };

          btnStartPause.addEventListener("click", () => {
            if (running) pause(); else start();
          });

          btnResetLap.addEventListener("click", () => {
            if (running) recordLap(); else reset();
          });
        },

        initTimer() {
          const display = document.getElementById("timer-display");
          const progressRing = document.getElementById("timer-progress-ring");
          const btnStartPause = document.getElementById("btn-timer-start-pause");
          const btnReset = document.getElementById("btn-timer-reset");
          const iconSpan = document.getElementById("icon-timer-play-pause");
          const lblSpan = document.getElementById("lbl-timer-start-pause");
          const statusText = document.getElementById("timer-status-text");

          const presetContainer = document.getElementById("timer-presets");
          const decMin = document.getElementById("btn-dec-min");
          const incMin = document.getElementById("btn-inc-min");
          const decSec = document.getElementById("btn-dec-sec");
          const incSec = document.getElementById("btn-inc-sec");

          let totalSeconds = 180;
          let remainingSeconds = 180;
          let running = false;
          this.timerInterval = null;

          const ringCircumference = 691.15;

          const updateDisplay = () => {
            const min = Math.floor(remainingSeconds / 60);
            const sec = remainingSeconds % 60;
            display.textContent = `${String(min).padStart(2, '0')}:${String(sec).padStart(2, '0')}`;

            const offset = ringCircumference * (1 - (remainingSeconds / totalSeconds));
            progressRing.style.strokeDashoffset = isNaN(offset) ? 0 : offset;
          };

          const triggerAlarm = () => {
            try {
              const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
              
              const playTone = (time, freq, duration) => {
                const osc = audioCtx.createOscillator();
                const gain = audioCtx.createGain();
                osc.type = "sine";
                osc.frequency.setValueAtTime(freq, time);
                gain.gain.setValueAtTime(0.2, time);
                gain.gain.exponentialRampToValueAtTime(0.01, time + duration - 0.02);
                osc.connect(gain);
                gain.connect(audioCtx.destination);
                osc.start(time);
                osc.stop(time + duration);
              };

              const now = audioCtx.currentTime;
              playTone(now, 880, 0.1);
              playTone(now + 0.15, 880, 0.1);
              playTone(now + 0.4, 880, 0.1);
              playTone(now + 0.55, 880, 0.1);
            } catch (err) {
              console.error("Audio feedback context failure", err);
            }
          };

          const tick = () => {
            if (remainingSeconds <= 0) {
              pause();
              triggerAlarm();
              statusText.textContent = "Finished!";
              statusText.classList.add("text-rose-500", "dark:text-rose-400", "animate-pulse");
              statusText.classList.remove("text-emerald-500", "dark:text-emerald-400");
              return;
            }
            remainingSeconds--;
            updateDisplay();
          };

          const start = () => {
            if (remainingSeconds <= 0) return;
            running = true;
            statusText.textContent = "Active";
            statusText.classList.remove("text-rose-500", "dark:text-rose-400", "animate-pulse", "text-slate-400");
            statusText.classList.add("text-emerald-500", "dark:text-emerald-400");

            iconSpan.innerHTML = '<span class="hero-pause size-4"></span>';
            lblSpan.textContent = "Pause";

            this.timerInterval = setInterval(tick, 1000);
          };

          const pause = () => {
            running = false;
            clearInterval(this.timerInterval);
            if (remainingSeconds > 0) {
              statusText.textContent = "Paused";
              statusText.classList.remove("text-emerald-500", "dark:text-emerald-400");
              statusText.classList.add("text-slate-400");
            }

            iconSpan.innerHTML = '<span class="hero-play size-4"></span>';
            lblSpan.textContent = "Start";
          };

          const reset = () => {
            pause();
            remainingSeconds = totalSeconds;
            statusText.textContent = "Ready";
            statusText.classList.remove("text-rose-500", "dark:text-rose-400", "animate-pulse", "text-emerald-500", "dark:text-emerald-400");
            statusText.classList.add("text-slate-400");
            updateDisplay();
          };

          presetContainer.addEventListener("click", (e) => {
            const button = e.target.closest("button");
            if (!button) return;
            const addSec = parseInt(button.dataset.seconds);
            if (running) {
              totalSeconds += addSec;
              remainingSeconds += addSec;
            } else {
              totalSeconds = Math.max(30, totalSeconds + addSec);
              remainingSeconds = totalSeconds;
            }
            updateDisplay();
          });

          decMin.addEventListener("click", () => {
            if (running) return;
            totalSeconds = Math.max(30, totalSeconds - 60);
            remainingSeconds = totalSeconds;
            updateDisplay();
          });
          incMin.addEventListener("click", () => {
            if (running) return;
            totalSeconds += 60;
            remainingSeconds = totalSeconds;
            updateDisplay();
          });

          decSec.addEventListener("click", () => {
            if (running) return;
            totalSeconds = Math.max(30, totalSeconds - 10);
            remainingSeconds = totalSeconds;
            updateDisplay();
          });
          incSec.addEventListener("click", () => {
            if (running) return;
            totalSeconds += 10;
            remainingSeconds = totalSeconds;
            updateDisplay();
          });

          btnStartPause.addEventListener("click", () => {
            if (running) pause(); else start();
          });

          btnReset.addEventListener("click", reset);

          updateDisplay();
        }
      }
    </script>
    """
  end
end
