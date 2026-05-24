import { createFileRoute, Link } from "@tanstack/react-router";
import { motion, useScroll, useTransform, AnimatePresence } from "framer-motion";
import { useEffect, useRef, useState } from "react";
import {
  Menu, X, ArrowRight, Search, MapPin, KeyRound, Star, Shield,
  Zap, Car, Wallet, Smartphone, MessageSquare, ChevronDown,
  Instagram, Twitter, Facebook, Github, Check,
} from "lucide-react";
import heroCar from "@/assets/hero-car.jpg";
import mapBg from "@/assets/map-bg.jpg";

export const Route = createFileRoute("/landing")({
  head: () => ({
    meta: [
      { title: "Drivly — Rent any car, anywhere. Drive smarter." },
      { name: "description", content: "Drivly is the peer-to-peer car rental platform. Discover thousands of cars near you, book in 60 seconds, unlock with your phone." },
      { property: "og:title", content: "Drivly — Drive smarter." },
      { property: "og:description", content: "Peer-to-peer car rental, reimagined. Book in 60 seconds." },
    ],
  }),
  component: Landing,
});

/* ---------- helpers ---------- */
const fadeUp = {
  hidden: { opacity: 0, y: 30 },
  show: { opacity: 1, y: 0, transition: { duration: 0.7, ease: [0.22, 1, 0.36, 1] as const } },
};

function Reveal({ children, delay = 0, className = "" }: { children: React.ReactNode; delay?: number; className?: string }) {
  return (
    <motion.div
      className={className}
      initial="hidden"
      whileInView="show"
      viewport={{ once: true, margin: "-80px" }}
      variants={{
        hidden: { opacity: 0, y: 30 },
        show: { opacity: 1, y: 0, transition: { duration: 0.7, delay, ease: [0.22, 1, 0.36, 1] as const } },
      }}
    >
      {children}
    </motion.div>
  );
}

/* ---------- NAV ---------- */
function Nav() {
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 20);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const links = [
    { href: "#features", label: "Features" },
    { href: "#how", label: "How it works" },
    { href: "#fleet", label: "Fleet" },
    { href: "#hosts", label: "Hosts" },
    { href: "#pricing", label: "Pricing" },
    { href: "#faq", label: "FAQ" },
  ];

  const go = (href: string) => {
    setOpen(false);
    const el = document.querySelector(href);
    if (el) el.scrollIntoView({ behavior: "smooth", block: "start" });
  };

  return (
    <motion.header
      initial={{ y: -40, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ duration: 0.6 }}
      className={`fixed top-0 inset-x-0 z-50 transition-all duration-300 ${
        scrolled ? "bg-background/80 backdrop-blur-xl border-b border-border" : "bg-transparent"
      }`}
    >
      <div className="max-w-7xl mx-auto px-6 md:px-10 h-16 md:h-18 flex items-center justify-between">
        <button onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })} className="font-display font-bold text-xl tracking-tight">
          drivly<span className="text-primary">.</span>
        </button>
        <nav className="hidden lg:flex items-center gap-8">
          {links.map((l) => (
            <button
              key={l.href}
              onClick={() => go(l.href)}
              className="text-sm text-muted-foreground hover:text-foreground transition-colors relative group"
            >
              {l.label}
              <span className="absolute -bottom-1 left-0 w-0 h-px bg-primary transition-all duration-300 group-hover:w-full" />
            </button>
          ))}
        </nav>
        <div className="hidden lg:flex items-center gap-3">
          <Link to="/" className="text-sm text-muted-foreground hover:text-foreground">Screens</Link>
          <button
            onClick={() => go("#cta")}
            className="bg-primary text-primary-foreground font-semibold px-5 py-2.5 rounded-full text-sm shadow-glow hover:shadow-[0_0_40px_oklch(0.88_0.21_130/0.6)] hover:-translate-y-0.5 transition-all"
          >
            Get the app
          </button>
        </div>
        <button onClick={() => setOpen(!open)} className="lg:hidden p-2 -mr-2">
          {open ? <X size={22} /> : <Menu size={22} />}
        </button>
      </div>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="lg:hidden bg-background/95 backdrop-blur-xl border-b border-border"
          >
            <div className="px-6 py-6 flex flex-col gap-4">
              {links.map((l) => (
                <button key={l.href} onClick={() => go(l.href)} className="text-left text-base text-foreground/90 py-1">
                  {l.label}
                </button>
              ))}
              <button
                onClick={() => go("#cta")}
                className="mt-2 bg-primary text-primary-foreground font-semibold px-5 py-3 rounded-full"
              >
                Get the app
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.header>
  );
}

/* ---------- HERO ---------- */
function Hero() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start start", "end start"] });
  const y = useTransform(scrollYProgress, [0, 1], [0, 200]);
  const carY = useTransform(scrollYProgress, [0, 1], [0, -80]);
  const carRot = useTransform(scrollYProgress, [0, 1], [0, -6]);
  const carScale = useTransform(scrollYProgress, [0, 1], [1, 1.05]);
  const opacity = useTransform(scrollYProgress, [0, 0.8], [1, 0]);

  return (
    <section ref={ref} className="relative min-h-screen overflow-hidden pt-28 md:pt-36 pb-20 bg-gradient-hero">
      {/* ambient blobs */}
      <motion.div style={{ y }} className="absolute inset-0 pointer-events-none">
        <div className="absolute top-20 -left-40 w-[500px] h-[500px] rounded-full bg-primary/25 blur-3xl animate-pulse" />
        <div className="absolute bottom-0 right-0 w-[600px] h-[600px] rounded-full bg-accent/20 blur-3xl" />
        <div className="absolute top-1/3 left-1/2 w-72 h-72 rounded-full bg-primary/10 blur-3xl" />
      </motion.div>

      {/* grid */}
      <div className="absolute inset-0 opacity-[0.07] pointer-events-none"
        style={{
          backgroundImage: "linear-gradient(var(--foreground) 1px, transparent 1px), linear-gradient(90deg, var(--foreground) 1px, transparent 1px)",
          backgroundSize: "60px 60px",
        }}
      />

      <motion.div style={{ opacity }} className="relative max-w-7xl mx-auto px-6 md:px-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-surface/60 backdrop-blur border border-border text-xs font-mono text-muted-foreground mb-6"
        >
          <span className="w-1.5 h-1.5 rounded-full bg-primary animate-pulse" />
          Now live in 30+ cities
        </motion.div>

        <motion.h1
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.9, ease: [0.22, 1, 0.36, 1] }}
          className="font-display font-bold text-5xl md:text-7xl lg:text-[104px] leading-[0.92] tracking-tight max-w-5xl"
        >
          Rent any car,<br />
          anywhere.{" "}
          <span className="relative inline-block">
            <span className="text-primary">Drive smarter.</span>
            <motion.span
              initial={{ scaleX: 0 }}
              animate={{ scaleX: 1 }}
              transition={{ delay: 1, duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
              className="absolute -bottom-2 left-0 right-0 h-1 bg-primary origin-left rounded-full"
            />
          </span>
        </motion.h1>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4, duration: 0.8 }}
          className="text-muted-foreground text-lg md:text-xl mt-8 max-w-xl leading-relaxed"
        >
          Drivly is the peer-to-peer car marketplace. Browse thousands of cars near you,
          book in 60 seconds, unlock with your phone. No counters. No queues.
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.6 }}
          className="flex flex-wrap gap-3 mt-10"
        >
          <button
            onClick={() => document.querySelector("#cta")?.scrollIntoView({ behavior: "smooth" })}
            className="group bg-primary text-primary-foreground font-semibold px-7 py-4 rounded-full shadow-glow hover:shadow-[0_0_60px_oklch(0.88_0.21_130/0.7)] hover:-translate-y-0.5 transition-all inline-flex items-center gap-2"
          >
            Get the app
            <ArrowRight size={18} className="group-hover:translate-x-1 transition-transform" />
          </button>
          <button
            onClick={() => document.querySelector("#how")?.scrollIntoView({ behavior: "smooth" })}
            className="bg-surface/60 backdrop-blur text-foreground font-semibold px-7 py-4 rounded-full border border-border hover:bg-surface transition-colors"
          >
            How it works
          </button>
        </motion.div>

        {/* hero car */}
        <motion.div
          style={{ y: carY, rotate: carRot, scale: carScale }}
          initial={{ opacity: 0, scale: 0.85, y: 60 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          transition={{ delay: 0.5, duration: 1.2, ease: [0.22, 1, 0.36, 1] }}
          className="relative mt-16 md:mt-20"
        >
          <div className="absolute inset-x-0 -bottom-10 h-40 bg-primary/30 blur-3xl rounded-full" />
          <img
            src={heroCar}
            alt="Drivly hero car"
            width={1600}
            height={1024}
            className="relative w-full max-w-5xl mx-auto rounded-3xl shadow-card"
          />
        </motion.div>

        {/* stats */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1 }}
          className="mt-20 grid grid-cols-2 md:grid-cols-4 gap-8 max-w-4xl mx-auto"
        >
          {[
            { v: "120K+", l: "Active drivers" },
            { v: "8K+", l: "Cars listed" },
            { v: "4.9★", l: "Avg. rating" },
            { v: "30+", l: "Cities" },
          ].map((s, i) => (
            <motion.div
              key={s.l}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: 0.1 * i }}
              className="text-center"
            >
              <p className="font-display font-bold text-4xl md:text-5xl text-primary">{s.v}</p>
              <p className="text-xs text-muted-foreground mt-2 uppercase tracking-widest">{s.l}</p>
            </motion.div>
          ))}
        </motion.div>
      </motion.div>
    </section>
  );
}

/* ---------- MARQUEE ---------- */
function Marquee() {
  const brands = ["TESLA", "BMW", "PORSCHE", "AUDI", "MERCEDES", "FERRARI", "LAMBORGHINI", "RANGE ROVER", "MCLAREN", "TOYOTA"];
  return (
    <section className="py-12 border-y border-border bg-surface/30 overflow-hidden">
      <p className="text-center text-xs uppercase tracking-widest text-muted-foreground mb-6">Trusted by drivers of</p>
      <div className="flex overflow-hidden">
        <motion.div
          animate={{ x: ["0%", "-50%"] }}
          transition={{ duration: 30, repeat: Infinity, ease: "linear" }}
          className="flex gap-16 shrink-0 pr-16"
        >
          {[...brands, ...brands].map((b, i) => (
            <span key={i} className="font-display font-bold text-2xl md:text-3xl text-muted-foreground/40 whitespace-nowrap">
              {b}
            </span>
          ))}
        </motion.div>
      </div>
    </section>
  );
}

/* ---------- FEATURES ---------- */
function Features() {
  const items = [
    { icon: Search, title: "Smart search", desc: "Filter by make, price, transmission, instant book. Find your car in seconds." },
    { icon: MapPin, title: "Live map", desc: "See every car around you in real time with price pins and availability." },
    { icon: KeyRound, title: "Keyless unlock", desc: "Tap to unlock supported cars right from the app. No key swap required." },
    { icon: Shield, title: "Full insurance", desc: "Every trip is protected with $1M liability and 24/7 roadside." },
    { icon: Wallet, title: "Wallet & rewards", desc: "Earn Drivly credits on every trip. Withdraw to bank in 1 tap." },
    { icon: MessageSquare, title: "In-app chat", desc: "Message hosts before, during and after the trip with photo proof." },
  ];

  return (
    <section id="features" className="py-24 md:py-32 px-6 md:px-10">
      <div className="max-w-7xl mx-auto">
        <Reveal>
          <p className="font-mono text-xs text-primary tracking-widest uppercase mb-3">01 · What you get</p>
          <h2 className="font-display font-bold text-4xl md:text-6xl tracking-tight max-w-3xl">
            Built for drivers who hate friction.
          </h2>
          <p className="text-muted-foreground mt-5 text-lg max-w-2xl">
            Every feature designed to remove a step. From discovery to drop-off, Drivly feels like one fluid motion.
          </p>
        </Reveal>

        <div className="mt-16 grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {items.map((it, i) => (
            <Reveal key={it.title} delay={i * 0.08}>
              <motion.div
                whileHover={{ y: -8 }}
                transition={{ type: "spring", stiffness: 300, damping: 20 }}
                className="group relative p-7 rounded-3xl bg-surface border border-border overflow-hidden cursor-pointer h-full"
              >
                <div className="absolute -top-20 -right-20 w-56 h-56 rounded-full bg-primary/0 group-hover:bg-primary/15 blur-3xl transition-all duration-500" />
                <div className="relative">
                  <div className="w-12 h-12 rounded-2xl bg-primary/10 border border-primary/30 flex items-center justify-center mb-5 group-hover:bg-primary group-hover:text-primary-foreground transition-colors">
                    <it.icon size={20} />
                  </div>
                  <h3 className="font-display font-bold text-xl mb-2">{it.title}</h3>
                  <p className="text-sm text-muted-foreground leading-relaxed">{it.desc}</p>
                </div>
              </motion.div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------- HOW IT WORKS ---------- */
function HowItWorks() {
  const steps = [
    { n: "01", title: "Find your car", desc: "Search by location, date, or vibe. Filter to your perfect match.", icon: Search },
    { n: "02", title: "Book in 60 seconds", desc: "Tap, confirm, pay. Get instant confirmation from the host.", icon: Smartphone },
    { n: "03", title: "Unlock & drive", desc: "Walk up, tap unlock, hit the road. We handle the rest.", icon: KeyRound },
    { n: "04", title: "Drop off & rate", desc: "Park, lock, leave a rating. Your wallet updates automatically.", icon: Star },
  ];

  return (
    <section id="how" className="relative py-24 md:py-32 px-6 md:px-10 overflow-hidden">
      <div
        className="absolute inset-0 opacity-20 pointer-events-none"
        style={{ backgroundImage: `url(${mapBg})`, backgroundSize: "cover", backgroundPosition: "center" }}
      />
      <div className="absolute inset-0 bg-gradient-to-b from-background via-background/60 to-background pointer-events-none" />

      <div className="relative max-w-7xl mx-auto">
        <Reveal>
          <p className="font-mono text-xs text-primary tracking-widest uppercase mb-3">02 · How it works</p>
          <h2 className="font-display font-bold text-4xl md:text-6xl tracking-tight max-w-3xl">
            Four taps from idea to ignition.
          </h2>
        </Reveal>

        <div className="mt-16 grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          {steps.map((s, i) => (
            <Reveal key={s.n} delay={i * 0.1}>
              <div className="relative p-7 rounded-3xl bg-surface/80 backdrop-blur border border-border h-full hover:border-primary/50 transition-colors group">
                <div className="flex items-center justify-between mb-6">
                  <span className="font-mono text-xs text-muted-foreground">{s.n}</span>
                  <s.icon size={20} className="text-primary group-hover:scale-110 transition-transform" />
                </div>
                <h3 className="font-display font-bold text-2xl mb-3">{s.title}</h3>
                <p className="text-sm text-muted-foreground leading-relaxed">{s.desc}</p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------- FLEET ---------- */
function Fleet() {
  const cars = [
    { name: "Tesla Model 3", type: "Electric", price: 89, rating: 4.9, trips: 142 },
    { name: "BMW M4 Competition", type: "Sport", price: 220, rating: 5.0, trips: 67 },
    { name: "Porsche 911 Carrera", type: "Luxury", price: 380, rating: 4.95, trips: 38 },
    { name: "Range Rover Sport", type: "SUV", price: 165, rating: 4.8, trips: 91 },
  ];

  return (
    <section id="fleet" className="py-24 md:py-32 px-6 md:px-10">
      <div className="max-w-7xl mx-auto">
        <div className="flex items-end justify-between flex-wrap gap-6 mb-14">
          <Reveal>
            <p className="font-mono text-xs text-primary tracking-widest uppercase mb-3">03 · The fleet</p>
            <h2 className="font-display font-bold text-4xl md:text-6xl tracking-tight max-w-3xl">
              From daily drivers to dream cars.
            </h2>
          </Reveal>
          <Reveal>
            <button className="text-sm font-semibold text-primary inline-flex items-center gap-2 hover:gap-3 transition-all">
              Browse all cars <ArrowRight size={16} />
            </button>
          </Reveal>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {cars.map((c, i) => (
            <Reveal key={c.name} delay={i * 0.08}>
              <motion.div
                whileHover={{ y: -10 }}
                transition={{ type: "spring", stiffness: 300 }}
                className="group rounded-3xl bg-surface border border-border overflow-hidden cursor-pointer h-full"
              >
                <div className="relative aspect-[4/3] bg-gradient-to-br from-surface-2 to-background overflow-hidden">
                  <div className="absolute inset-0 flex items-center justify-center">
                    <Car size={80} className="text-primary/60 group-hover:scale-110 group-hover:text-primary transition-all duration-500" strokeWidth={1} />
                  </div>
                  <div className="absolute top-3 left-3 px-2.5 py-1 rounded-full bg-background/70 backdrop-blur text-[10px] font-mono uppercase tracking-wider">
                    {c.type}
                  </div>
                  <div className="absolute top-3 right-3 px-2.5 py-1 rounded-full bg-primary text-primary-foreground text-[10px] font-bold inline-flex items-center gap-1">
                    <Star size={10} fill="currentColor" /> {c.rating}
                  </div>
                </div>
                <div className="p-5">
                  <h3 className="font-display font-bold text-lg mb-1">{c.name}</h3>
                  <p className="text-xs text-muted-foreground mb-4">{c.trips} trips · Instant book</p>
                  <div className="flex items-end justify-between">
                    <div>
                      <span className="font-display font-bold text-2xl text-primary">${c.price}</span>
                      <span className="text-xs text-muted-foreground"> / day</span>
                    </div>
                    <button className="text-xs font-semibold px-3 py-2 rounded-full bg-surface-2 border border-border group-hover:bg-primary group-hover:text-primary-foreground group-hover:border-primary transition-all">
                      Book
                    </button>
                  </div>
                </div>
              </motion.div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------- HOSTS ---------- */
function Hosts() {
  return (
    <section id="hosts" className="py-24 md:py-32 px-6 md:px-10">
      <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-16 items-center">
        <Reveal>
          <p className="font-mono text-xs text-primary tracking-widest uppercase mb-3">04 · For hosts</p>
          <h2 className="font-display font-bold text-4xl md:text-6xl tracking-tight">
            Your car. Your terms. Your <span className="text-primary">payout.</span>
          </h2>
          <p className="text-muted-foreground mt-5 text-lg leading-relaxed">
            Turn your parked car into a side business. Hosts earn an average of $750/month with zero upfront cost.
          </p>
          <ul className="mt-8 space-y-4">
            {[
              "Free listing, no monthly fees",
              "$1M liability insurance per trip",
              "Smart pricing optimized by AI",
              "Weekly payouts straight to your bank",
            ].map((t, i) => (
              <Reveal key={t} delay={i * 0.05}>
                <li className="flex items-start gap-3">
                  <span className="mt-0.5 w-6 h-6 rounded-full bg-primary text-primary-foreground flex items-center justify-center shrink-0">
                    <Check size={14} strokeWidth={3} />
                  </span>
                  <span className="text-foreground/90">{t}</span>
                </li>
              </Reveal>
            ))}
          </ul>
          <button className="mt-10 bg-primary text-primary-foreground font-semibold px-7 py-4 rounded-full shadow-glow hover:-translate-y-0.5 transition-all inline-flex items-center gap-2">
            Become a host <ArrowRight size={18} />
          </button>
        </Reveal>

        <Reveal delay={0.2}>
          <div className="relative">
            <motion.div
              animate={{ y: [0, -12, 0] }}
              transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
              className="relative rounded-3xl bg-surface border border-border p-7 shadow-card"
            >
              <div className="flex items-center justify-between mb-5">
                <div>
                  <p className="text-xs text-muted-foreground uppercase tracking-widest">This month</p>
                  <p className="font-display font-bold text-4xl mt-1">$2,847<span className="text-base text-muted-foreground">.20</span></p>
                </div>
                <div className="px-3 py-1.5 rounded-full bg-primary/10 border border-primary/30 text-primary text-xs font-semibold">
                  +24% MoM
                </div>
              </div>
              <div className="h-32 flex items-end gap-2">
                {[40, 65, 35, 80, 55, 95, 70, 100, 60, 85, 75, 90].map((h, i) => (
                  <motion.div
                    key={i}
                    initial={{ height: 0 }}
                    whileInView={{ height: `${h}%` }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.8, delay: i * 0.05, ease: [0.22, 1, 0.36, 1] }}
                    className="flex-1 rounded-t-md bg-gradient-to-t from-primary/40 to-primary"
                  />
                ))}
              </div>
              <div className="mt-5 pt-5 border-t border-border grid grid-cols-3 gap-4 text-center">
                <div><p className="font-display font-bold text-xl">23</p><p className="text-xs text-muted-foreground">Trips</p></div>
                <div><p className="font-display font-bold text-xl">4.96</p><p className="text-xs text-muted-foreground">Rating</p></div>
                <div><p className="font-display font-bold text-xl">98%</p><p className="text-xs text-muted-foreground">Accept</p></div>
              </div>
            </motion.div>
            <motion.div
              animate={{ y: [0, 14, 0] }}
              transition={{ duration: 7, repeat: Infinity, ease: "easeInOut" }}
              className="absolute -bottom-8 -right-4 md:-right-10 w-52 p-4 rounded-2xl bg-surface-2 border border-border shadow-card"
            >
              <div className="flex items-center gap-2 mb-2">
                <Zap size={14} className="text-primary" />
                <p className="text-xs font-semibold">Booking confirmed</p>
              </div>
              <p className="text-xs text-muted-foreground">Marcus rented your BMW M4 — $440 / 2 days</p>
            </motion.div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

/* ---------- TESTIMONIALS ---------- */
function Testimonials() {
  const t = [
    { name: "Sarah K.", role: "Host · LA", quote: "Made $9,400 in 4 months renting my Tesla. The app does literally everything for me." },
    { name: "James M.", role: "Driver · NYC", quote: "Booked a Porsche for my anniversary in 45 seconds. Unlocked with my phone. Pure magic." },
    { name: "Priya R.", role: "Host · Austin", quote: "The smart pricing and calendar sync made hosting feel passive. I check the app once a week." },
    { name: "Alex T.", role: "Driver · Miami", quote: "I haven't owned a car in two years. Drivly is cheaper, easier and never the same car twice." },
  ];

  return (
    <section className="py-24 md:py-32 px-6 md:px-10 border-y border-border bg-surface/30">
      <div className="max-w-7xl mx-auto">
        <Reveal>
          <p className="font-mono text-xs text-primary tracking-widest uppercase mb-3">05 · Loved by both sides</p>
          <h2 className="font-display font-bold text-4xl md:text-6xl tracking-tight max-w-3xl">
            120,000+ drivers and hosts agree.
          </h2>
        </Reveal>
        <div className="mt-14 grid sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {t.map((it, i) => (
            <Reveal key={it.name} delay={i * 0.08}>
              <div className="p-6 rounded-3xl bg-background border border-border h-full hover:border-primary/40 transition-colors">
                <div className="flex gap-0.5 mb-4">
                  {[...Array(5)].map((_, k) => <Star key={k} size={14} className="text-primary" fill="currentColor" />)}
                </div>
                <p className="text-sm leading-relaxed mb-5">"{it.quote}"</p>
                <div className="pt-4 border-t border-border">
                  <p className="font-semibold text-sm">{it.name}</p>
                  <p className="text-xs text-muted-foreground">{it.role}</p>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------- PRICING ---------- */
function Pricing() {
  const plans = [
    { name: "Driver", price: "Free", desc: "For everyone who rents.", features: ["Unlimited bookings", "$1M insurance included", "Live chat support", "Wallet & rewards"], cta: "Download app", featured: false },
    { name: "Host", price: "0%", suffix: "setup", desc: "List your car. Get paid.", features: ["Free listing", "Smart pricing AI", "Calendar sync", "Weekly payouts", "Pro analytics"], cta: "Start hosting", featured: true },
    { name: "Fleet", price: "Custom", desc: "10+ vehicles? Talk to sales.", features: ["Dedicated manager", "API access", "Bulk uploads", "Custom contracts", "Priority support"], cta: "Contact sales", featured: false },
  ];

  return (
    <section id="pricing" className="py-24 md:py-32 px-6 md:px-10">
      <div className="max-w-7xl mx-auto">
        <Reveal>
          <p className="font-mono text-xs text-primary tracking-widest uppercase mb-3">06 · Pricing</p>
          <h2 className="font-display font-bold text-4xl md:text-6xl tracking-tight max-w-3xl">
            Honest pricing. Zero surprises.
          </h2>
        </Reveal>

        <div className="mt-16 grid md:grid-cols-3 gap-5">
          {plans.map((p, i) => (
            <Reveal key={p.name} delay={i * 0.1}>
              <motion.div
                whileHover={{ y: -8 }}
                transition={{ type: "spring", stiffness: 300 }}
                className={`relative p-8 rounded-3xl border h-full ${
                  p.featured
                    ? "bg-gradient-to-b from-primary/10 to-surface border-primary/50 shadow-glow"
                    : "bg-surface border-border"
                }`}
              >
                {p.featured && (
                  <div className="absolute -top-3 left-8 px-3 py-1 rounded-full bg-primary text-primary-foreground text-[10px] font-bold uppercase tracking-wider">
                    Most popular
                  </div>
                )}
                <h3 className="font-display font-bold text-2xl">{p.name}</h3>
                <p className="text-sm text-muted-foreground mt-1">{p.desc}</p>
                <div className="mt-6 flex items-baseline gap-2">
                  <span className="font-display font-bold text-5xl">{p.price}</span>
                  {p.suffix && <span className="text-sm text-muted-foreground">{p.suffix}</span>}
                </div>
                <ul className="mt-8 space-y-3">
                  {p.features.map((f) => (
                    <li key={f} className="flex items-start gap-2 text-sm">
                      <Check size={16} className="text-primary mt-0.5 shrink-0" strokeWidth={3} />
                      {f}
                    </li>
                  ))}
                </ul>
                <button
                  className={`mt-8 w-full py-3.5 rounded-full font-semibold transition-all ${
                    p.featured
                      ? "bg-primary text-primary-foreground hover:-translate-y-0.5 shadow-glow"
                      : "bg-surface-2 border border-border hover:bg-surface-2/70"
                  }`}
                >
                  {p.cta}
                </button>
              </motion.div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------- FAQ ---------- */
function FAQ() {
  const [open, setOpen] = useState<number | null>(0);
  const faqs = [
    { q: "How does insurance work?", a: "Every Drivly trip includes $1M liability coverage and 24/7 roadside assistance — for both drivers and hosts. No paperwork required." },
    { q: "Do I need to meet the host?", a: "Most cars support contactless keyless unlock right from the app. For older vehicles, you'll do a quick 60-second handoff with the host." },
    { q: "What does it cost to list my car?", a: "Listing is free. Drivly takes a 25% service fee per booking which covers insurance, support and platform costs." },
    { q: "How fast do hosts get paid?", a: "Hosts receive weekly payouts every Monday. You can also withdraw on-demand for a $1 fee." },
    { q: "Can I cancel a booking?", a: "Yes — free cancellation up to 24 hours before pickup. After that, a partial fee applies based on host policy." },
    { q: "What cities are you live in?", a: "30+ cities across North America with new launches every month. Check the app for your area." },
  ];

  return (
    <section id="faq" className="py-24 md:py-32 px-6 md:px-10">
      <div className="max-w-4xl mx-auto">
        <Reveal>
          <p className="font-mono text-xs text-primary tracking-widest uppercase mb-3">07 · FAQ</p>
          <h2 className="font-display font-bold text-4xl md:text-6xl tracking-tight">
            Questions? Answered.
          </h2>
        </Reveal>
        <div className="mt-12 space-y-3">
          {faqs.map((f, i) => (
            <Reveal key={f.q} delay={i * 0.05}>
              <div className="rounded-2xl bg-surface border border-border overflow-hidden">
                <button
                  onClick={() => setOpen(open === i ? null : i)}
                  className="w-full px-6 py-5 flex items-center justify-between text-left hover:bg-surface-2/40 transition-colors"
                >
                  <span className="font-semibold text-base md:text-lg">{f.q}</span>
                  <motion.span animate={{ rotate: open === i ? 180 : 0 }} transition={{ duration: 0.3 }}>
                    <ChevronDown size={20} className="text-primary" />
                  </motion.span>
                </button>
                <AnimatePresence initial={false}>
                  {open === i && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: "auto", opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
                      className="overflow-hidden"
                    >
                      <p className="px-6 pb-5 text-muted-foreground leading-relaxed">{f.a}</p>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------- CTA ---------- */
function CTA() {
  return (
    <section id="cta" className="py-24 md:py-32 px-6 md:px-10">
      <div className="relative max-w-6xl mx-auto rounded-3xl overflow-hidden bg-gradient-hero border border-border p-10 md:p-20 text-center">
        <div className="absolute inset-0 opacity-40 pointer-events-none">
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[600px] rounded-full bg-primary/30 blur-3xl" />
        </div>
        <Reveal>
          <p className="font-mono text-xs text-primary tracking-widest uppercase mb-4">Ready to drive?</p>
          <h2 className="font-display font-bold text-4xl md:text-7xl tracking-tight">
            Your next car<br />is one tap away.
          </h2>
          <p className="text-muted-foreground text-lg mt-6 max-w-xl mx-auto">
            Download Drivly free. Get $25 in credit on your first ride.
          </p>
          <div className="flex flex-wrap justify-center gap-3 mt-10">
            <button className="bg-primary text-primary-foreground font-semibold px-8 py-4 rounded-full shadow-glow hover:-translate-y-0.5 transition-all inline-flex items-center gap-2">
              <Smartphone size={18} /> Download iOS
            </button>
            <button className="bg-surface text-foreground font-semibold px-8 py-4 rounded-full border border-border hover:bg-surface-2 transition-colors inline-flex items-center gap-2">
              <Smartphone size={18} /> Get on Android
            </button>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

/* ---------- FOOTER ---------- */
function Footer() {
  const cols = [
    { title: "Product", links: ["Features", "How it works", "Fleet", "Pricing", "Download"] },
    { title: "Company", links: ["About", "Careers", "Press", "Blog", "Contact"] },
    { title: "Support", links: ["Help center", "Safety", "Insurance", "Trust", "Cities"] },
    { title: "Legal", links: ["Terms", "Privacy", "Cookies", "Licenses"] },
  ];
  return (
    <footer className="border-t border-border pt-16 pb-10 px-6 md:px-10 bg-surface/30">
      <div className="max-w-7xl mx-auto">
        <div className="grid lg:grid-cols-6 gap-10">
          <div className="lg:col-span-2">
            <p className="font-display font-bold text-2xl">drivly<span className="text-primary">.</span></p>
            <p className="text-sm text-muted-foreground mt-3 max-w-xs">
              The peer-to-peer car rental marketplace. Drive smarter — anywhere, anytime.
            </p>
            <div className="flex gap-3 mt-6">
              {[Twitter, Instagram, Facebook, Github].map((Icon, i) => (
                <a key={i} href="#" className="w-10 h-10 rounded-full bg-surface-2 border border-border flex items-center justify-center hover:bg-primary hover:text-primary-foreground hover:border-primary transition-all">
                  <Icon size={16} />
                </a>
              ))}
            </div>
          </div>
          {cols.map((c) => (
            <div key={c.title}>
              <p className="font-semibold text-sm mb-4">{c.title}</p>
              <ul className="space-y-3">
                {c.links.map((l) => (
                  <li key={l}><a href="#" className="text-sm text-muted-foreground hover:text-foreground transition-colors">{l}</a></li>
                ))}
              </ul>
            </div>
          ))}
        </div>
        <div className="mt-14 pt-6 border-t border-border flex justify-between items-center flex-wrap gap-3 text-xs text-muted-foreground font-mono">
          <span>© 2026 Drivly Inc. All rights reserved.</span>
          <span>Made with ⚡ for drivers everywhere.</span>
        </div>
      </div>
    </footer>
  );
}

/* ---------- PAGE ---------- */
function Landing() {
  return (
    <div className="min-h-screen bg-background text-foreground overflow-x-hidden">
      <Nav />
      <Hero />
      <Marquee />
      <Features />
      <HowItWorks />
      <Fleet />
      <Hosts />
      <Testimonials />
      <Pricing />
      <FAQ />
      <CTA />
      <Footer />
    </div>
  );
}
