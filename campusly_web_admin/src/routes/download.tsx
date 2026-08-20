import { createFileRoute } from "@tanstack/react-router";
import { Download, Smartphone, ShieldCheck, ArrowRight } from "lucide-react";
import { motion } from "framer-motion";

export const Route = createFileRoute("/download")({
  component: DownloadAppPage,
});

function DownloadAppPage() {
  return (
    <div className="min-h-screen bg-zinc-50 flex flex-col items-center justify-center p-4">
      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="max-w-md w-full bg-white rounded-3xl shadow-xl overflow-hidden border border-zinc-100"
      >
        <div className="p-8 text-center bg-blue-600 text-white">
          <div className="w-16 h-16 bg-white/20 rounded-2xl flex items-center justify-center mx-auto mb-6 backdrop-blur-sm">
            <Smartphone className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-2xl font-bold mb-2">Campusly App</h1>
          <p className="text-blue-100">Get the official college app on your Android device.</p>
        </div>
        
        <div className="p-8 space-y-6">
          <a
            href="/campusly-app.apk"
            download
            className="flex items-center justify-center w-full py-4 px-6 bg-zinc-900 text-white rounded-xl font-medium hover:bg-zinc-800 transition-colors gap-3"
          >
            <Download className="w-5 h-5" />
            Download APK
          </a>

          <div className="bg-amber-50 border border-amber-100 rounded-xl p-4 flex gap-3 text-left">
            <ShieldCheck className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
            <div className="text-sm text-amber-900">
              <span className="font-semibold block mb-1">Installation Guide:</span>
              When you download the file, your phone might ask for permission to install apps from unknown sources. Go to Settings and enable "Allow from this source" to complete the installation.
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  );
}
