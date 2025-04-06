# Swicord

**Swicord** is an experimental iOS app to connect to the [Discord Gateway API](https://discord.com/developers/docs/topics/gateway) and customize Discord Rich Presence, using Swift + Starscream (WebSocket client).

---

## Features

- Connect to Discord Gateway as a **bot client**
- Update Rich Presence with customizable activities, states, timestamps, and buttons
- Lightweight customizable Discord bot presence editor
- Includes spoof mode: simulate presence locally **without actual Discord connection**
- No server hosting needed – just a native app with your bot token

---

## ⚠️ Important — Account Token Usage is Patched & Unsupported

### Why user account tokens **WON'T work anymore

Originally, some apps connected **pretending to be a Discord user account** (a "self-bot"). This is now **strictly forbidden** and **technically patched by Discord**:

- **Gateway servers still respond to account tokens with initial `HELLO` packet**
- However, **after Identify is received** with an account token, Discord **immediately disconnects the WebSocket** or closes the session silently
- The Gateway expects **valid bot Identify payloads**, including the `"intents"` key
- Even if you mimic Identify as a **Discord client** (mobile or desktop), the server can detect it is not legitimate
- Discord now **filters and throttles** unauthorized user tokens on Gateway **almost instantly**

### What does this mean?

- **Swicord does _NOT_ support connecting with your Discord account token**
- **If you try to do this, the connection _will fail_ or your account _might get flagged/banned_**
- This is a **Discord infrastructure restriction** at the WebSocket login handshake layer
- For any reliable presence update via Gateway, **your only option now is a Discord bot token**

---

## Supported Use Case:

- Create a **Discord bot application** in the [Developer Portal](https://discord.com/developers/applications)
- Invite the bot to your server(s)
- Use the **bot token** for Swicord
- Your bot’s presence/status **will be updated accordingly**
- This approach **follows Discord's Terms of Service**

---

## Setup Guide

1. Create a bot:
   - Visit https://discord.com/developers/applications
   - Create an application
   - Add a bot user
   - **Copy your bot token**
   - Enable **Gateway Intents** (Presence, Guilds) under "Bot > Privileged Gateway Intents" if needed
   - **Invite** the bot to your server with proper permissions

2. Build Swicord with Xcode or TrollStore-compatible signing.

3. Enter the bot token in your Swicord app.

4. Use the app to connect, customize presence, or spoof locally.

---

## Limitations

- Does **not** support user account rich presence or client modding
- Presence updates **reflect on the bot only**
- Account tokens **will be rejected**; no selfbot functionality
- Using **any account token connection is unsupported and disabled by Discord infrastructure**

---

## Disclaimer

This is an educational, open-source project exploring the Discord Gateway API.

**Do NOT attempt to use user tokens or self-botting capabilities**, as these violate Discord's Terms of Service and can risk account termination.

Always use bot tokens for legitimate testing or integrations.

---

## License

MIT License.

Use at your own risk.

---

## Credits

- [Discord API Docs](https://discord.com/developers/docs/)
- [Starscream](https://github.com/daltoniam/Starscream)
