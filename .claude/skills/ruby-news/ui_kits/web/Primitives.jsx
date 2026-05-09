// Ruby News web UI kit — primitives.
// Tailwind-free; styled via colors_and_type.css custom properties + inline class names
// resolved by ./kit.css. Mirrors RubyUI / Phlex semantics from the ra-news codebase.

const cn = (...parts) => parts.filter(Boolean).join(" ");

// ─── Button ────────────────────────────────────────────────────────────────
function Button({ variant = "primary", size = "md", icon, children, className = "", ...rest }) {
    return (
        <button
            type={rest.type ?? "button"}
            className={cn("rn-btn", `rn-btn--${variant}`, `rn-btn--${size}`, icon && "rn-btn--icon", className)}
            {...rest}>
            {children}
        </button>
    );
}

// ─── Badge / Pill ──────────────────────────────────────────────────────────
function Badge({ variant = "neutral", size = "sm", className = "", children }) {
    return <span className={cn("rn-badge", `rn-badge--${variant}`, `rn-badge--${size}`, className)}>{children}</span>;
}

// ─── Card ──────────────────────────────────────────────────────────────────
function Card({ className = "", children, ...rest }) {
    return <div className={cn("rn-card", className)} {...rest}>{children}</div>;
}
function CardContent({ className = "", children }) {
    return <div className={cn("rn-card__content", className)}>{children}</div>;
}

// ─── Avatar ────────────────────────────────────────────────────────────────
function Avatar({ name, size = "md", tone = "brand" }) {
    const initials = (name || "")
        .split(/\s+/)
        .filter(Boolean)
        .slice(0, 2)
        .map((s) => s[0])
        .join("")
        .toUpperCase() || "?";
    return <span className={cn("rn-avatar", `rn-avatar--${size}`, `rn-avatar--${tone}`)} aria-hidden="true">{initials}</span>;
}

// ─── Heading ───────────────────────────────────────────────────────────────
function Heading({ level = 2, className = "", children, ...rest }) {
    const Tag = `h${level}`;
    return <Tag className={cn(`rn-h${level}`, className)} {...rest}>{children}</Tag>;
}

// ─── Separator ─────────────────────────────────────────────────────────────
function Separator({ className = "" }) {
    return <hr className={cn("rn-separator", className)} aria-hidden="true" />;
}

// ─── Form field ────────────────────────────────────────────────────────────
function FormField({ label, htmlFor, error, hint, children }) {
    return (
        <div className="rn-formfield">
            {label && <label className="rn-formfield__label" htmlFor={htmlFor}>{label}</label>}
            {children}
            {hint && !error && <div className="rn-formfield__hint">{hint}</div>}
            {error && <div className="rn-formfield__error">{error}</div>}
        </div>
    );
}

function TextInput({ className = "", ...rest }) {
    return <input className={cn("rn-input", className)} {...rest} />;
}
function TextArea({ className = "", ...rest }) {
    return <textarea className={cn("rn-input rn-input--textarea", className)} {...rest} />;
}

const Input = TextInput;
Object.assign(window, { cn, Button, Badge, Card, CardContent, Avatar, Heading, Separator, FormField, TextInput, Input, TextArea });
