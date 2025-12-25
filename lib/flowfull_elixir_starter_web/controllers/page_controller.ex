defmodule FlowfullElixirStarterWeb.PageController do
  use FlowfullElixirStarterWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def health(conn, _params) do
    json(conn, %{status: "ok"})
  end

  def user(conn, _params) do
    # Public test route: returns a mock user
    json(conn, %{
      id: "test-user-123",
      email: "user@example.com",
      name: "Test User"
    })
  end

  def me(conn, _params) do
    case conn.assigns[:auth_claims] do
      nil ->
        conn
        |> put_status(401)
        |> json(%{error: "unauthorized"})

      claims ->
        json(conn, %{
          id: claims["user_id"],
          email: claims["email"],
          token_type: claims["token_type"]
        })
    end
  end

  def ws(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>WebSocket Test - Flowfull Elixir Starter</title>
      <style>
        * { box-sizing: border-box; }
        body { 
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; 
          margin: 0; 
          padding: 20px;
          background: #f5f5f5;
        }
        .container {
          max-width: 800px;
          margin: 0 auto;
          background: white;
          padding: 30px;
          border-radius: 8px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        h2 { margin-top: 0; color: #333; }
        .section { margin: 20px 0; padding: 15px; background: #f9f9f9; border-radius: 4px; }
        .section h3 { margin-top: 0; font-size: 16px; color: #666; }
        input { 
          padding: 8px 12px; 
          border: 1px solid #ddd; 
          border-radius: 4px; 
          font-size: 14px;
          width: 300px;
        }
        button { 
          padding: 8px 16px; 
          margin: 4px; 
          border: none; 
          border-radius: 4px; 
          background: #4CAF50; 
          color: white; 
          cursor: pointer;
          font-size: 14px;
          font-weight: 500;
        }
        button:hover { background: #45a049; }
        button:disabled { background: #ccc; cursor: not-allowed; }
        button.secondary { background: #2196F3; }
        button.secondary:hover { background: #0b7dda; }
        button.danger { background: #f44336; }
        button.danger:hover { background: #da190b; }
        #log { 
          border: 1px solid #ddd; 
          padding: 12px; 
          height: 300px; 
          overflow: auto; 
          background: #1e1e1e;
          color: #d4d4d4;
          font-family: 'Courier New', monospace;
          font-size: 13px;
          border-radius: 4px;
          line-height: 1.4;
        }
        .status { 
          display: inline-block;
          padding: 4px 8px;
          border-radius: 3px;
          font-size: 12px;
          font-weight: 600;
          margin-left: 8px;
        }
        .status.connected { background: #4CAF50; color: white; }
        .status.disconnected { background: #f44336; color: white; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>🔌 WebSocket Test</h2>
        
        <div class="section">
          <h3>1. Connection</h3>
          <input id="sid" placeholder="session_id (optional)" />
          <button id="connect">Connect</button>
          <button id="disconnect" class="danger" disabled>Disconnect</button>
          <span id="status" class="status disconnected">DISCONNECTED</span>
        </div>

        <div class="section">
          <h3>2. Join Channels</h3>
          <div style="margin-bottom:8px;">
            <label>Public topic:&nbsp;</label>
            <input id="public_topic" value="lobby" />
            <button id="join_public" class="secondary" disabled>Join public:&lt;topic&gt;</button>
          </div>
          <div>
            <label>Secure topic:&nbsp;</label>
            <input id="secure_topic" value="room" />
            <button id="join_secure" class="secondary" disabled>Join secure:&lt;topic&gt;</button>
          </div>
        </div>

        <div class="section">
          <h3>3. Send Messages</h3>
          <div style="margin-bottom:8px;">
            <label>Event:&nbsp;</label>
            <input id="event_name" value="ping" />
          </div>
          <div style="margin-bottom:8px;">
            <label>Payload (JSON):&nbsp;</label>
            <input id="payload_json" value="{\"message\": \"hello\"}" style="width: 100%;" />
          </div>
          <div style="margin-bottom:8px;">
            <label>Send to:&nbsp;</label>
            <label><input type="checkbox" id="send_public" checked /> public</label>
            <label style="margin-left:10px;"><input type="checkbox" id="send_secure" checked /> secure</label>
          </div>
          <button id="send" disabled>Send</button>
          <button id="clear" class="secondary">Clear Log</button>
        </div>

        <div class="section">
          <h3>Console Log</h3>
          <pre id="log"></pre>
        </div>
      </div>

      <script src="https://cdn.jsdelivr.net/npm/phoenix@1.7.10/priv/static/phoenix.min.js"></script>
      <script>
        const { Socket } = window.Phoenix;
        let socket, publicChan, secureChan;
        
        const logEl = document.getElementById('log');
        const statusEl = document.getElementById('status');
        const connectBtn = document.getElementById('connect');
        const disconnectBtn = document.getElementById('disconnect');
        const joinPublicBtn = document.getElementById('join_public');
        const joinSecureBtn = document.getElementById('join_secure');
        const sendBtn = document.getElementById('send');
        const clearBtn = document.getElementById('clear');
        const sidInput = document.getElementById('sid');
        const publicTopicInput = document.getElementById('public_topic');
        const secureTopicInput = document.getElementById('secure_topic');
        const eventNameInput = document.getElementById('event_name');
        const payloadJsonInput = document.getElementById('payload_json');
        const sendPublicChk = document.getElementById('send_public');
        const sendSecureChk = document.getElementById('send_secure');

        function log(msg, type = 'info') {
          const timestamp = new Date().toLocaleTimeString();
          const prefix = type === 'error' ? '❌' : type === 'success' ? '✅' : type === 'send' ? '📤' : '📥';
          logEl.textContent += `[${timestamp}] ${prefix} ${msg}\\n`;
          logEl.scrollTop = logEl.scrollHeight;
        }

        function updateStatus(connected) {
          if (connected) {
            statusEl.textContent = 'CONNECTED';
            statusEl.className = 'status connected';
            connectBtn.disabled = true;
            disconnectBtn.disabled = false;
            joinPublicBtn.disabled = false;
            joinSecureBtn.disabled = false;
          } else {
            statusEl.textContent = 'DISCONNECTED';
            statusEl.className = 'status disconnected';
            connectBtn.disabled = false;
            disconnectBtn.disabled = true;
            joinPublicBtn.disabled = true;
            joinSecureBtn.disabled = true;
            sendBtn.disabled = true;
          }
        }

        connectBtn.onclick = () => {
          const sid = sidInput.value.trim();
          const params = sid ? { session_id: sid } : {};
          
          log('Connecting to WebSocket...', 'info');
          socket = new Socket('/socket', { params });
          
          socket.onOpen(() => {
            log('WebSocket connected!', 'success');
            updateStatus(true);
            // Auto-join public on connect
            joinPublicBtn.click();
          });
          
          socket.onClose(() => {
            log('WebSocket disconnected', 'error');
            updateStatus(false);
          });
          
          socket.onError((err) => {
            log('WebSocket error: ' + err, 'error');
          });
          
          socket.connect();
        };

        disconnectBtn.onclick = () => {
          if (socket) {
            socket.disconnect();
            publicChan = null;
            secureChan = null;
            log('Disconnected by user', 'info');
          }
        };

        joinPublicBtn.onclick = () => {
          if (!socket) return;
          const topic = publicTopicInput.value.trim() || 'lobby';
          log('Joining public:' + topic + '...', 'info');
          publicChan = socket.channel('public:' + topic, {});
          
          publicChan.join()
            .receive('ok', () => {
              log('✓ Joined public:' + topic, 'success');
              sendBtn.disabled = false;
            })
            .receive('error', (err) => {
              log('✗ Failed to join public: ' + JSON.stringify(err), 'error');
            });
          
          publicChan.on('pong', (payload) => {
            log('Public channel PONG: ' + JSON.stringify(payload), 'info');
          });
        };

        joinSecureBtn.onclick = () => {
          if (!socket) return;
          const topic = secureTopicInput.value.trim() || 'room';
          log('Joining secure:' + topic + '...', 'info');
          secureChan = socket.channel('secure:' + topic, {});
          
          secureChan.join()
            .receive('ok', () => {
              log('✓ Joined secure:' + topic, 'success');
              sendBtn.disabled = false;
            })
            .receive('error', (err) => {
              log('✗ Failed to join secure: ' + JSON.stringify(err), 'error');
            });
          
          secureChan.on('pong', (payload) => {
            log('Secure channel PONG: ' + JSON.stringify(payload), 'info');
          });
        };

        sendBtn.onclick = () => {
          let eventName = (eventNameInput.value || '').trim();
          if (!eventName) eventName = 'ping';
          let payload = { timestamp: Date.now() };
          try {
            const parsed = JSON.parse(payloadJsonInput.value || '{}');
            payload = { ...payload, ...parsed };
          } catch (e) {
            log('Invalid JSON payload: ' + e.message, 'error');
          }

          const sent = [];
          if (sendPublicChk.checked && publicChan) {
            log('Sending ' + eventName + ' to public', 'send');
            publicChan.push(eventName, payload);
            sent.push('public');
          }
          if (sendSecureChk.checked && secureChan) {
            log('Sending ' + eventName + ' to secure', 'send');
            secureChan.push(eventName, payload);
            sent.push('secure');
          }
          if (sent.length === 0) {
            log('No target channels joined or selected!', 'error');
          }
        };

        clearBtn.onclick = () => {
          logEl.textContent = '';
          log('Log cleared', 'info');
        };

        // Initial log
        log('WebSocket test page loaded. Click Connect to start.', 'info');
      </script>
    </body>
    </html>
    """)
  end
end
