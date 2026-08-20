import { createFileRoute } from "@tanstack/react-router";
import { Download, Smartphone, ShieldCheck, CheckCircle2, HelpCircle, Mail, Calendar, Users, Bell, Star } from "lucide-react";
import { motion } from "framer-motion";
import { useQuery, useMutation } from "@tanstack/react-query";
import { marketingQueries, testimonialsQueries, api } from "@/lib/services";
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";
import { useState } from "react";

export const Route = createFileRoute("/download")({
  component: DownloadLandingPage,
});

function DownloadLandingPage() {
  const CURRENT_VERSION = "v1.0.2 (Beta)";
  const RELEASE_DATE = "August 20, 2026";
  const FILE_SIZE = "24.5 MB";

  const { data: downloadCount = 0 } = useQuery(marketingQueries.downloads());
  const { data: testimonials = [] } = useQuery(testimonialsQueries.publicList());

  const trackDownload = useMutation({
    mutationFn: () => api.marketing.trackDownload(navigator.userAgent),
  });

  const handleDownload = () => {
    trackDownload.mutate();
    // Proceed with the default anchor download behavior
  };

  return (
    <div className="min-h-screen bg-zinc-50 font-sans text-zinc-900 selection:bg-blue-200">
      
      {/* Navbar */}
      <nav className="fixed top-0 inset-x-0 h-16 bg-white/80 backdrop-blur-lg border-b border-zinc-200 z-50 flex items-center px-4 sm:px-8">
        <div className="max-w-6xl mx-auto w-full flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center">
              <Smartphone className="w-4 h-4 text-white" />
            </div>
            <span className="font-bold text-xl tracking-tight">Campusly</span>
          </div>
          <a
            href="/campusly-app.apk"
            download
            onClick={handleDownload}
            className="hidden sm:flex items-center gap-2 bg-zinc-900 text-white px-4 py-2 rounded-full text-sm font-medium hover:bg-zinc-800 transition-colors shadow-sm"
          >
            <Download className="w-4 h-4" />
            Download APK
          </a>
        </div>
      </nav>

      <main className="pt-16">
        
        {/* Hero Section */}
        <section className="relative overflow-hidden bg-white pb-20 pt-24 sm:pt-32">
          {/* Decorative background blur */}
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[500px] bg-blue-50/50 rounded-full blur-3xl -z-10 pointer-events-none" />
          
          <div className="max-w-6xl mx-auto px-4 sm:px-8 flex flex-col items-center text-center">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
              className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-50 border border-blue-100 text-blue-600 text-sm font-medium mb-8"
            >
              <span className="w-2 h-2 rounded-full bg-blue-600 animate-pulse" />
              Campusly for Android is here
            </motion.div>

            <motion.h1 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
              className="text-5xl sm:text-7xl font-bold tracking-tight text-zinc-900 max-w-3xl mb-6"
            >
              Your entire campus, <span className="text-blue-600">in your pocket.</span>
            </motion.h1>

            <motion.p 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.2 }}
              className="text-lg sm:text-xl text-zinc-500 max-w-2xl mb-10"
            >
              Access timetables, track attendance, and stay updated with campus events instantly. The official app for students and faculty.
            </motion.p>

            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.3 }}
              className="flex flex-col sm:flex-row items-center gap-4 w-full sm:w-auto"
            >
              <a
                href="/campusly-app.apk"
                download
                onClick={handleDownload}
                className="w-full sm:w-auto flex items-center justify-center gap-2 bg-blue-600 text-white px-8 py-4 rounded-2xl text-lg font-medium hover:bg-blue-700 transition-all hover:scale-105 active:scale-95 shadow-xl shadow-blue-600/20"
              >
                <Download className="w-5 h-5" />
                Download App (APK)
              </a>
              <div className="flex flex-col items-center sm:items-start text-sm text-zinc-500 px-4">
                <span className="font-medium text-zinc-900">Version {CURRENT_VERSION}</span>
                <span>{FILE_SIZE} • Released {RELEASE_DATE}</span>
              </div>
            </motion.div>

            {/* Quick trust indicators */}
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.5, delay: 0.5 }}
              className="mt-12 flex flex-wrap items-center justify-center gap-6 sm:gap-12 text-sm text-zinc-500"
            >
              <div className="flex items-center gap-2"><CheckCircle2 className="w-4 h-4 text-green-500" /> Secure Download</div>
              <div className="flex items-center gap-2"><ShieldCheck className="w-4 h-4 text-blue-500" /> Official College App</div>
              <div className="flex items-center gap-2 font-semibold text-zinc-800 bg-zinc-100 px-3 py-1.5 rounded-lg">
                <Download className="w-4 h-4" /> {downloadCount.toLocaleString()}+ Downloads
              </div>
            </motion.div>
          </div>
        </section>

        {/* Features Grid */}
        <section className="py-24 bg-zinc-50 border-t border-zinc-100">
          <div className="max-w-6xl mx-auto px-4 sm:px-8">
            <div className="text-center mb-16">
              <h2 className="text-3xl font-bold tracking-tight mb-4">Everything you need</h2>
              <p className="text-zinc-500 max-w-2xl mx-auto">Designed specifically to make your college life easier.</p>
            </div>

            <div className="grid sm:grid-cols-3 gap-8">
              <div className="bg-white p-8 rounded-3xl shadow-sm border border-zinc-100">
                <div className="w-12 h-12 bg-blue-50 rounded-2xl flex items-center justify-center mb-6">
                  <Calendar className="w-6 h-6 text-blue-600" />
                </div>
                <h3 className="text-xl font-semibold mb-2">Smart Timetable</h3>
                <p className="text-zinc-500">View your daily classes, venues, and faculty details. Never miss a class again.</p>
              </div>
              <div className="bg-white p-8 rounded-3xl shadow-sm border border-zinc-100">
                <div className="w-12 h-12 bg-emerald-50 rounded-2xl flex items-center justify-center mb-6">
                  <Users className="w-6 h-6 text-emerald-600" />
                </div>
                <h3 className="text-xl font-semibold mb-2">Live Attendance</h3>
                <p className="text-zinc-500">Track your attendance percentage in real-time and avoid falling below the criteria.</p>
              </div>
              <div className="bg-white p-8 rounded-3xl shadow-sm border border-zinc-100">
                <div className="w-12 h-12 bg-amber-50 rounded-2xl flex items-center justify-center mb-6">
                  <Bell className="w-6 h-6 text-amber-600" />
                </div>
                <h3 className="text-xl font-semibold mb-2">Instant Alerts</h3>
                <p className="text-zinc-500">Get push notifications for canceled classes, rescheduled exams, and campus events.</p>
              </div>
            </div>
          </div>
        </section>

        {/* Testimonials */}
        {testimonials.length > 0 && (
          <section className="py-24 bg-white border-t border-zinc-100">
            <div className="max-w-6xl mx-auto px-4 sm:px-8">
              <div className="text-center mb-16">
                <h2 className="text-3xl font-bold tracking-tight mb-4">Loved by Students</h2>
                <p className="text-zinc-500 max-w-2xl mx-auto">Don't just take our word for it. Here is what your peers think about Campusly.</p>
              </div>
              <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
                {testimonials.map((t: any) => (
                  <div key={t.id} className="bg-zinc-50 p-8 rounded-3xl border border-zinc-100 flex flex-col h-full">
                    <div className="flex gap-1 mb-4">
                      {Array.from({ length: t.rating }).map((_, i) => (
                        <Star key={i} className="w-4 h-4 fill-amber-400 text-amber-400" />
                      ))}
                    </div>
                    <p className="text-zinc-700 italic flex-grow mb-6">"{t.content}"</p>
                    <div className="mt-auto flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-700 font-bold">
                        {t.author_name.charAt(0)}
                      </div>
                      <div>
                        <p className="font-semibold text-zinc-900 text-sm">{t.author_name}</p>
                        <p className="text-xs text-zinc-500">{t.author_role}</p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </section>
        )}

        {/* Installation Guide & FAQ */}
        <section className="py-24 bg-zinc-50 border-t border-zinc-100">
          <div className="max-w-4xl mx-auto px-4 sm:px-8">
            <div className="grid md:grid-cols-2 gap-16">
              
              {/* Left Column: Installation Guide */}
              <div>
                <h2 className="text-2xl font-bold mb-6">How to Install</h2>
                
                <ol className="relative border-l border-zinc-200 ml-3 space-y-8">
                  <li className="pl-8 relative">
                    <span className="absolute -left-4 flex items-center justify-center w-8 h-8 rounded-full bg-blue-100 ring-4 ring-zinc-50 text-blue-600 font-bold text-sm">1</span>
                    <h3 className="font-semibold text-zinc-900 mb-1">Download the APK</h3>
                    <p className="text-sm text-zinc-500">Click the download button above to save the .apk file to your device.</p>
                  </li>
                  <li className="pl-8 relative">
                    <span className="absolute -left-4 flex items-center justify-center w-8 h-8 rounded-full bg-blue-100 ring-4 ring-zinc-50 text-blue-600 font-bold text-sm">2</span>
                    <h3 className="font-semibold text-zinc-900 mb-1">Open the file</h3>
                    <p className="text-sm text-zinc-500">Tap on the downloaded file in your browser's downloads list or file manager.</p>
                  </li>
                  <li className="pl-8 relative">
                    <span className="absolute -left-4 flex items-center justify-center w-8 h-8 rounded-full bg-blue-100 ring-4 ring-zinc-50 text-blue-600 font-bold text-sm">3</span>
                    <h3 className="font-semibold text-zinc-900 mb-1">Allow Unknown Sources</h3>
                    <p className="text-sm text-zinc-500">If prompted, click "Settings" and toggle on "Allow from this source". This is required since the app isn't on the Play Store yet.</p>
                    <div className="mt-3 p-3 bg-amber-50 rounded-lg border border-amber-100 flex gap-3 items-start">
                      <ShieldCheck className="w-5 h-5 text-amber-600 shrink-0" />
                      <p className="text-xs text-amber-800">This warning is normal for APKs. The app is 100% safe and developed directly by the college.</p>
                    </div>
                  </li>
                  <li className="pl-8 relative">
                    <span className="absolute -left-4 flex items-center justify-center w-8 h-8 rounded-full bg-blue-100 ring-4 ring-zinc-50 text-blue-600 font-bold text-sm">4</span>
                    <h3 className="font-semibold text-zinc-900 mb-1">Install and Login</h3>
                    <p className="text-sm text-zinc-500">Click "Install". Once finished, open the app and log in with your student portal credentials.</p>
                  </li>
                </ol>
              </div>

              {/* Right Column: FAQ */}
              <div>
                <h2 className="text-2xl font-bold mb-6">Frequently Asked Questions</h2>
                <Accordion type="single" collapsible className="w-full">
                  <AccordionItem value="item-1">
                    <AccordionTrigger className="text-left font-medium">Why isn't it on the Play Store?</AccordionTrigger>
                    <AccordionContent className="text-zinc-500 leading-relaxed">
                      We are currently in a Beta testing phase to gather feedback and ensure everything runs smoothly before a public release. We plan to launch it on the Google Play Store soon.
                    </AccordionContent>
                  </AccordionItem>
                  <AccordionItem value="item-2">
                    <AccordionTrigger className="text-left font-medium">Is there an iOS version?</AccordionTrigger>
                    <AccordionContent className="text-zinc-500 leading-relaxed">
                      The iOS version is currently in development. For now, iPhone users can access all features through the responsive student web portal.
                    </AccordionContent>
                  </AccordionItem>
                  <AccordionItem value="item-3">
                    <AccordionTrigger className="text-left font-medium">Is it safe to bypass the installation warning?</AccordionTrigger>
                    <AccordionContent className="text-zinc-500 leading-relaxed">
                      Yes. Android displays a standard warning for any app not downloaded from the Play Store. This APK is compiled and signed securely by our IT department.
                    </AccordionContent>
                  </AccordionItem>
                  <AccordionItem value="item-4">
                    <AccordionTrigger className="text-left font-medium">How do I update the app?</AccordionTrigger>
                    <AccordionContent className="text-zinc-500 leading-relaxed">
                      When a new version is released, you'll see a notification inside the app. You can simply return to this page, download the new APK, and install it over the old one. Your data will remain intact.
                    </AccordionContent>
                  </AccordionItem>
                </Accordion>
              </div>
            </div>
          </div>
        </section>

        {/* Support Section */}
        <section className="py-20 bg-zinc-900 text-white">
          <div className="max-w-4xl mx-auto px-4 sm:px-8 text-center">
            <div className="w-16 h-16 bg-white/10 rounded-full flex items-center justify-center mx-auto mb-6">
              <HelpCircle className="w-8 h-8 text-white" />
            </div>
            <h2 className="text-3xl font-bold mb-4">Need help?</h2>
            <p className="text-zinc-400 mb-8 max-w-xl mx-auto">
              If you're having trouble downloading, installing, or logging into the app, our IT support team is here to help.
            </p>
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
              <a href="mailto:support@campusly.edu" className="flex items-center gap-2 bg-white text-zinc-900 px-6 py-3 rounded-xl font-medium hover:bg-zinc-100 transition-colors">
                <Mail className="w-4 h-4" />
                support@campusly.edu
              </a>
              <span className="text-zinc-500">or visit the IT Helpdesk in Block A</span>
            </div>
          </div>
        </section>

      </main>
      
      {/* Footer */}
      <footer className="py-8 text-center text-zinc-500 border-t border-zinc-200">
        <p>© {new Date().getFullYear()} Campusly. Built for students.</p>
      </footer>
    </div>
  );
}
