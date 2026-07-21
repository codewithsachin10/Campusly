import React, { useState, useEffect } from 'react';
import { signOut } from 'firebase/auth';
import { 
  collection, 
  doc, 
  addDoc, 
  deleteDoc, 
  updateDoc,
  onSnapshot 
} from 'firebase/firestore';
import { auth, db } from '../firebase';

export default function Dashboard({ user, onLogout }) {
  const [activeTab, setActiveTab] = useState('overview'); // overview, app_updates, notice_board, faculty
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState('');
  
  // Real database states
  const [students, setStudents] = useState([]);
  const [faculty, setFaculty] = useState([]);
  const [announcements, setAnnouncements] = useState([]);
  const [appConfig, setAppConfig] = useState([]);

  // Selection states
  const [selectedFaculty, setSelectedFaculty] = useState(null);
  
  // Search & Filter states
  const [facultySearch, setFacultySearch] = useState('');
  const [facultyDeptFilter, setFacultyDeptFilter] = useState('All');

  // Modal / Form trigger states
  const [modalType, setModalType] = useState(null); // 'add_faculty'
  const [confirmDialog, setConfirmDialog] = useState(null); // { type, message, action, data }

  // Form states
  const [facultyForm, setFacultyForm] = useState({
    name: '',
    email: '',
    department: 'Computer Science',
    cabin: ''
  });

  const [noticeForm, setNoticeForm] = useState({
    title: 'Internal Assessment Schedule',
    details: 'The internal assessment for the Second Semester will commence from next Monday. Please find the detailed room allocation and schedule attached on the portal. All students must bring their ID cards.',
    isHighPriority: true
  });

  const [appUpdateForm, setAppUpdateForm] = useState({
    versionCode: '3',
    versionName: '1.0.2',
    priorityMode: 'Flexible', // Flexible, Critical
    apkUrl: 'https://cdn.campusly.io/releases/v102/android_prod.apk',
    releaseNotes: '• Dark Mode support\n• Performance improvements\n• Fixed login issue for faculty accounts\n• Added Dark Mode support for Student Dashboard'
  });

  // Toast trigger utility
  const showToast = (msg) => {
    setToast(msg);
    setTimeout(() => setToast(''), 3000);
  };

  // Setup Real-time Database listeners
  useEffect(() => {
    setLoading(true);

    // 1. Listen for Students (to get live counts)
    const unsubStudents = onSnapshot(collection(db, 'users'), (snap) => {
      const list = [];
      snap.forEach(d => list.push({ id: d.id, ...d.data() }));
      setStudents(list);
      setLoading(false);
    }, (err) => {
      console.error(err);
      setLoading(false);
    });

    // 2. Listen for Faculty
    const unsubFaculty = onSnapshot(collection(db, 'faculties'), (snap) => {
      const list = [];
      snap.forEach(d => list.push({ id: d.id, ...d.data() }));
      setFaculty(list);
    }, (err) => console.error(err));

    // 3. Listen for Announcements (Notice Board)
    const unsubAnnouncements = onSnapshot(collection(db, 'announcements'), (snap) => {
      const list = [];
      snap.forEach(d => list.push({ id: d.id, ...d.data() }));
      list.sort((a, b) => (b.timestamp?.seconds || 0) - (a.timestamp?.seconds || 0));
      setAnnouncements(list);
    }, (err) => console.error(err));

    // 4. Listen for App Config (App Updates)
    const unsubAppConfig = onSnapshot(collection(db, 'app_config'), (snap) => {
      const list = [];
      snap.forEach(d => list.push({ id: d.id, ...d.data() }));
      list.sort((a, b) => (b.timestamp?.seconds || 0) - (a.timestamp?.seconds || 0));
      setAppConfig(list);
    }, (err) => console.error(err));

    return () => {
      unsubStudents();
      unsubFaculty();
      unsubAnnouncements();
      unsubAppConfig();
    };
  }, []);

  // Add Faculty Handler
  const handleAddFaculty = async (e) => {
    e.preventDefault();
    if (!facultyForm.name || !facultyForm.email || !facultyForm.cabin) return;
    try {
      await addDoc(collection(db, 'faculties'), {
        name: facultyForm.name,
        email: facultyForm.email,
        department: facultyForm.department,
        cabin: facultyForm.cabin
      });
      setFacultyForm({
        name: '',
        email: '',
        department: 'Computer Science',
        cabin: ''
      });
      setModalType(null);
      showToast('Faculty added successfully.');
    } catch (err) {
      console.error(err);
      alert('Something went wrong. Please try again.');
    }
  };

  // Delete Faculty Handler
  const handleDeleteFaculty = async (facultyId) => {
    try {
      await deleteDoc(doc(db, 'faculties', facultyId));
      setConfirmDialog(null);
      setSelectedFaculty(null);
      showToast('Faculty profile deleted successfully.');
    } catch (err) {
      console.error(err);
      alert('Something went wrong. Please try again.');
    }
  };

  // Publish Notice Handler
  const handlePublishNotice = async (e) => {
    e.preventDefault();
    if (!noticeForm.title || !noticeForm.details) return;
    try {
      await addDoc(collection(db, 'announcements'), {
        title: noticeForm.title,
        details: noticeForm.details,
        isHighPriority: noticeForm.isHighPriority,
        timestamp: new Date()
      });
      setNoticeForm({
        title: '',
        details: '',
        isHighPriority: false
      });
      showToast('Notice published successfully.');
    } catch (err) {
      console.error(err);
      showToast('Error publishing notice.');
    }
  };

  // Delete Notice Handler
  const handleDeleteNotice = async (noticeId) => {
    try {
      await deleteDoc(doc(db, 'announcements', noticeId));
      showToast('Notice removed successfully.');
    } catch (err) {
      console.error(err);
    }
  };

  // Publish App Update Handler
  const handlePublishUpdate = async (e) => {
    e.preventDefault();
    if (!appUpdateForm.versionCode || !appUpdateForm.versionName || !appUpdateForm.apkUrl) return;
    try {
      await addDoc(collection(db, 'app_config'), {
        versionCode: Number(appUpdateForm.versionCode),
        versionName: appUpdateForm.versionName,
        priorityMode: appUpdateForm.priorityMode,
        apkUrl: appUpdateForm.apkUrl,
        releaseNotes: appUpdateForm.releaseNotes,
        timestamp: new Date()
      });
      showToast('App update published successfully.');
    } catch (err) {
      console.error(err);
      showToast('Error publishing update.');
    }
  };

  // Faculty filtering
  const filteredFaculty = faculty.filter(f => {
    const matchesSearch = (f.name?.toLowerCase().includes(facultySearch.toLowerCase()) || 
                           f.email?.toLowerCase().includes(facultySearch.toLowerCase()) ||
                           f.cabin?.toLowerCase().includes(facultySearch.toLowerCase()));
    const matchesDept = facultyDeptFilter === 'All' || f.department === facultyDeptFilter;
    return matchesSearch && matchesDept;
  });

  // Latest release details
  const currentRelease = appConfig[0] || {
    versionCode: 2,
    versionName: '1.0.1',
    priorityMode: 'Flexible',
    apkUrl: 'https://cdn.campusly.io/releases/v102/android_prod.apk',
    releaseNotes: 'Improved timetable experience and bug fixes related to push notifications for the faculty notices.'
  };

  return (
    <div className="min-h-screen bg-background flex text-on-surface overflow-hidden">

      {/* LEFT SIDEBAR */}
      <aside className="fixed left-0 top-0 h-full w-[260px] bg-surface-container-lowest border-r border-outline-variant flex flex-col justify-between py-6 px-4 z-50">
        
        {/* Top Branding & Nav */}
        <div className="space-y-10">
          {/* Logo */}
          <div className="mb-10 px-2 flex items-center gap-3">
            <div className="w-10 h-10 bg-secondary rounded-lg flex items-center justify-center text-white">
              <span className="material-symbols-outlined text-white" style={{ fontVariationSettings: "'FILL' 1" }}>school</span>
            </div>
            <div>
              <h1 className="font-headline-lg text-headline-lg font-black text-on-surface leading-none">Campusly</h1>
              <p className="font-label-md text-label-md text-on-surface-variant">Admin Portal</p>
            </div>
          </div>

          {/* Navigation Links */}
          <nav className="space-y-1">
            <button 
              onClick={() => { setActiveTab('overview'); setSelectedFaculty(null); }}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg font-body-md text-body-md transition-all active:scale-95 duration-150 relative ${
                activeTab === 'overview' 
                  ? 'bg-surface-container-high text-secondary border-l-[3px] border-secondary font-semibold' 
                  : 'text-on-surface-variant hover:bg-surface-container-low'
              }`}
            >
              <span className="material-symbols-outlined" style={activeTab === 'overview' ? { fontVariationSettings: "'FILL' 1" } : {}}>dashboard</span>
              <span>Overview</span>
            </button>
            <button 
              onClick={() => { setActiveTab('app_updates'); setSelectedFaculty(null); }}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg font-body-md text-body-md transition-all active:scale-95 duration-150 relative ${
                activeTab === 'app_updates' 
                  ? 'bg-surface-container-high text-secondary border-l-[3px] border-secondary font-semibold' 
                  : 'text-on-surface-variant hover:bg-surface-container-low'
              }`}
            >
              <span className="material-symbols-outlined" style={activeTab === 'app_updates' ? { fontVariationSettings: "'FILL' 1" } : {}}>system_update</span>
              <span>App Updates</span>
            </button>
            <button 
              onClick={() => { setActiveTab('notice_board'); setSelectedFaculty(null); }}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg font-body-md text-body-md transition-all active:scale-95 duration-150 relative ${
                activeTab === 'notice_board' 
                  ? 'bg-surface-container-high text-secondary border-l-[3px] border-secondary font-semibold' 
                  : 'text-on-surface-variant hover:bg-surface-container-low'
              }`}
            >
              <span className="material-symbols-outlined" style={activeTab === 'notice_board' ? { fontVariationSettings: "'FILL' 1" } : {}}>campaign</span>
              <span>Notice Board</span>
            </button>
            <button 
              onClick={() => { setActiveTab('faculty'); setSelectedFaculty(null); }}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg font-body-md text-body-md transition-all active:scale-95 duration-150 relative ${
                activeTab === 'faculty' 
                  ? 'bg-surface-container-high text-secondary border-l-[3px] border-secondary font-semibold' 
                  : 'text-on-surface-variant hover:bg-surface-container-low'
              }`}
            >
              <span className="material-symbols-outlined" style={activeTab === 'faculty' ? { fontVariationSettings: "'FILL' 1" } : {}}>group</span>
              <span>Faculty Directory</span>
            </button>
          </nav>
        </div>

        {/* Bottom Profile & Logout */}
        <div className="mt-auto border-t border-outline-variant pt-4 space-y-1">
          <div className="px-3 py-2">
            <p className="text-[10px] font-bold text-on-surface-variant uppercase tracking-wider mb-1 leading-none">Administrator</p>
            <p className="text-xs font-bold text-on-surface truncate" title={user?.email}>{user?.email || 'codewithsachin10@gmail.com'}</p>
          </div>
          <button 
            onClick={onLogout}
            className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg font-body-md text-error hover:bg-error-container/20 transition-colors cursor-pointer"
          >
            <span className="material-symbols-outlined">logout</span>
            <span>Logout</span>
          </button>
        </div>

      </aside>

      {/* MAIN WORKSPACE CANVAS */}
      <main className="ml-[260px] min-h-screen flex flex-col relative overflow-y-auto h-screen custom-scrollbar w-[calc(100vw-260px)]">

        {/* Top App Bar */}
        <header className="sticky top-0 z-40 h-16 px-10 bg-surface border-b border-outline-variant flex justify-between items-center flex-shrink-0">
          <div className="flex items-center gap-4">
            <h2 className="font-headline-md text-headline-md font-bold text-on-surface">
              {activeTab === 'overview' && 'System Overview'}
              {activeTab === 'app_updates' && 'App Updates'}
              {activeTab === 'notice_board' && 'Notice Board'}
              {activeTab === 'faculty' && 'Faculty Directory'}
            </h2>
            <div className="h-4 w-[1px] bg-outline-variant"></div>
            <span className="text-on-surface-variant font-label-md text-label-md">Last synced: 2m ago</span>
          </div>
          <div className="flex items-center gap-6">
            <button className="font-label-md text-label-md text-primary font-bold hover:bg-surface-container p-2 rounded-lg transition-all flex items-center gap-1">
              <span className="material-symbols-outlined text-[18px]">refresh</span> Refresh
            </button>
            <div className="relative">
              <span className="material-symbols-outlined text-on-surface-variant cursor-pointer hover:bg-surface-container rounded-full p-2 transition-all">notifications</span>
              <span className="absolute top-2 right-2 w-2 h-2 bg-error rounded-full border-2 border-surface"></span>
            </div>
            <div className="w-8 h-8 rounded-full bg-secondary-container text-on-secondary-container flex items-center justify-center font-bold text-[12px]">
              AD
            </div>
          </div>
        </header>

        {/* Canvas area wrapper */}
        <div className="flex-1 px-10 py-8 max-w-[1440px] w-full">
          {loading ? (
            <div className="space-y-6">
              <div className="h-6 w-48 bg-slate-200 rounded animate-pulse"></div>
              <div className="h-4 w-64 bg-slate-200 rounded animate-pulse"></div>
              <div className="grid grid-cols-4 gap-6 pt-6">
                {[1, 2, 3, 4].map(n => (
                  <div key={n} className="bg-white border border-outline-variant p-6 rounded-xl space-y-3 shadow-sm h-32 animate-pulse">
                    <div className="h-4 w-20 bg-slate-200 rounded"></div>
                    <div className="h-8 w-24 bg-slate-200 rounded"></div>
                  </div>
                ))}
              </div>
              <div className="bg-white border border-outline-variant rounded-xl h-[400px] animate-pulse"></div>
            </div>
          ) : (
            <div className="space-y-8 animate-fade-in">
              
              {/* ============================== PAGE 3: OVERVIEW TAB ============================== */}
              {activeTab === 'overview' && (
                <div className="space-y-8">
                  {/* Page Header */}
                  <div>
                    <h3 className="font-headline-lg text-headline-lg text-on-surface mb-1">System Overview</h3>
                    <p className="font-body-lg text-body-lg text-on-surface-variant">Monitor the current health of the Campusly ecosystem.</p>
                  </div>

                  {/* 4 Statistics grid */}
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                    <div className="bg-white border border-outline-variant p-5 rounded-xl shadow-sm">
                      <div className="flex justify-between items-start mb-4">
                        <div className="p-2 rounded-lg bg-surface-container-low text-secondary flex items-center justify-center">
                          <span className="material-symbols-outlined">person</span>
                        </div>
                        <span className="px-2 py-0.5 bg-emerald-100 text-emerald-800 text-[10px] font-bold rounded uppercase tracking-wider">Live</span>
                      </div>
                      <p className="font-label-md text-label-md text-on-surface-variant uppercase tracking-tight">Total Enrolled Students</p>
                      <h3 className="font-headline-lg text-headline-lg mt-1">{students.length > 0 ? students.length.toLocaleString() : '1,248'}</h3>
                    </div>
                    <div className="bg-white border border-outline-variant p-5 rounded-xl shadow-sm">
                      <div className="flex justify-between items-start mb-4">
                        <div className="p-2 rounded-lg bg-surface-container-low text-secondary flex items-center justify-center">
                          <span className="material-symbols-outlined">notifications_active</span>
                        </div>
                        <span className="text-on-surface-variant font-label-md text-xs">Currently visible</span>
                      </div>
                      <p className="font-label-md text-label-md text-on-surface-variant uppercase tracking-tight">Active Notices</p>
                      <h3 className="font-headline-lg text-headline-lg mt-1">{announcements.length > 0 ? announcements.length : '12'}</h3>
                    </div>
                    <div className="bg-white border border-outline-variant p-5 rounded-xl shadow-sm">
                      <div className="flex justify-between items-start mb-4">
                        <div className="p-2 rounded-lg bg-surface-container-low text-secondary flex items-center justify-center">
                          <span className="material-symbols-outlined">id_card</span>
                        </div>
                        <span className="text-on-surface-variant font-label-md text-xs">Profiles available</span>
                      </div>
                      <p className="font-label-md text-label-md text-on-surface-variant uppercase tracking-tight">Faculty Directory</p>
                      <h3 className="font-headline-lg text-headline-lg mt-1">{faculty.length > 0 ? faculty.length : '86'}</h3>
                    </div>
                    <div className="bg-white border border-outline-variant p-5 rounded-xl shadow-sm">
                      <div className="flex justify-between items-start mb-4">
                        <div className="p-2 rounded-lg bg-surface-container-low text-secondary flex items-center justify-center">
                          <span className="material-symbols-outlined">deployed_code</span>
                        </div>
                        <span className="px-2 py-0.5 bg-blue-100 text-blue-800 text-[10px] font-bold rounded uppercase tracking-wider">Latest release</span>
                      </div>
                      <p className="font-label-md text-label-md text-on-surface-variant uppercase tracking-tight">Current App Version</p>
                      <h3 className="font-headline-lg text-headline-lg mt-1">{currentRelease.versionName}</h3>
                    </div>
                  </div>

                  {/* Main content split */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
                    
                    {/* Left: release details & analytics */}
                    <div className="lg:col-span-8 space-y-6">
                      
                      {/* Live Application Release Card */}
                      <div className="bg-white border border-outline-variant rounded-xl shadow-sm overflow-hidden">
                        <div className="p-6 border-b border-outline-variant flex justify-between items-center bg-surface">
                          <h4 className="font-title-lg text-title-lg text-on-surface">Live Application Release</h4>
                          <button 
                            onClick={() => setActiveTab('app_updates')}
                            className="px-4 py-2 bg-primary text-white font-label-md text-label-md rounded-lg hover:opacity-90 transition-opacity cursor-pointer font-bold"
                          >
                            Manage Release
                          </button>
                        </div>
                        <div className="p-8 space-y-6">
                          <div className="flex flex-col md:flex-row gap-8">
                            <div className="w-full md:w-1/3 flex flex-col items-center justify-center p-6 bg-surface-container-low rounded-2xl border border-outline-variant">
                              <div className="w-16 h-16 bg-white rounded-2xl shadow-sm flex items-center justify-center mb-4 text-secondary">
                                <span className="material-symbols-outlined text-[36px]" style={{ fontVariationSettings: "'FILL' 1" }}>android</span>
                              </div>
                              <span className="font-headline-lg text-headline-lg text-on-surface">{currentRelease.versionName}</span>
                              <span className="text-on-surface-variant font-label-sm text-label-sm uppercase mt-1">Production</span>
                            </div>
                            <div className="w-full md:w-2/3 grid grid-cols-2 gap-6">
                              <div className="space-y-1">
                                <p className="text-on-surface-variant font-label-sm text-label-sm uppercase">Version Code</p>
                                <p className="font-title-lg text-title-lg text-on-surface font-semibold">{currentRelease.versionCode}</p>
                              </div>
                              <div className="space-y-1">
                                <p className="text-on-surface-variant font-label-sm text-label-sm uppercase">Update Priority</p>
                                <p className="font-title-lg text-title-lg text-on-surface font-semibold">{currentRelease.priorityMode} Update</p>
                              </div>
                              <div className="space-y-1">
                                <p className="text-on-surface-variant font-label-sm text-label-sm uppercase">Status</p>
                                <div className="flex items-center gap-2">
                                  <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
                                  <p className="font-title-lg text-title-lg text-on-surface font-semibold">Active</p>
                                </div>
                              </div>
                              <div className="space-y-1">
                                <p className="text-on-surface-variant font-label-sm text-label-sm uppercase">Source</p>
                                <div className="flex items-center gap-2 text-on-surface">
                                  <span className="material-symbols-outlined text-[20px]">hub</span>
                                  <p className="font-title-lg text-title-lg font-semibold">GitHub Releases</p>
                                </div>
                              </div>
                            </div>
                          </div>
                          
                          {/* Release notes block */}
                          <div className="p-5 bg-surface-container rounded-xl border border-outline-variant">
                            <p className="font-label-md text-label-md text-on-surface-variant uppercase mb-2">Release Notes</p>
                            <p className="text-on-surface font-body-md text-body-md leading-relaxed whitespace-pre-line">
                              {currentRelease.releaseNotes}
                            </p>
                          </div>
                        </div>
                      </div>

                      {/* Historical Data Analytics block */}
                      <div className="bg-surface-container-lowest rounded-xl border border-outline-variant shadow-soft h-60 flex items-center justify-center border-dashed">
                        <div className="text-center">
                          <span className="material-symbols-outlined text-outline-variant text-[48px]">monitoring</span>
                          <p className="text-on-surface-variant font-label-md text-label-md mt-2">Historical data analytics coming soon</p>
                        </div>
                      </div>

                    </div>

                    {/* Right: Recent activity logs timeline */}
                    <div className="lg:col-span-4">
                      <div className="bg-white border border-outline-variant rounded-xl shadow-sm flex flex-col h-full">
                        <div className="p-6 border-b border-outline-variant">
                          <h4 className="font-title-lg text-title-lg text-on-surface">Recent Activity</h4>
                        </div>
                        <div className="p-6 space-y-8 flex-grow">
                          
                          {/* Timeline Item 1 */}
                          <div className="relative flex gap-4 items-start">
                            <div className="w-10 h-10 rounded-full border border-outline-variant bg-white text-secondary flex items-center justify-center flex-shrink-0 z-10">
                              <span className="material-symbols-outlined text-[20px]">person_add</span>
                            </div>
                            <div className="flex-1">
                              <div className="flex justify-between items-baseline">
                                <span className="font-body-md text-body-md font-semibold text-on-surface">New student joined</span>
                                <time className="text-[10px] text-on-surface-variant font-semibold">5m ago</time>
                              </div>
                              <p className="text-on-surface-variant text-xs mt-0.5">Aditya Sharma enrolled in B.Tech CS</p>
                            </div>
                          </div>

                          {/* Timeline Item 2 */}
                          <div className="relative flex gap-4 items-start">
                            <div className="w-10 h-10 rounded-full border border-outline-variant bg-white text-secondary flex items-center justify-center flex-shrink-0 z-10">
                              <span className="material-symbols-outlined text-[20px]">campaign</span>
                            </div>
                            <div className="flex-1">
                              <div className="flex justify-between items-baseline">
                                <span className="font-body-md text-body-md font-semibold text-on-surface">Notice published</span>
                                <time className="text-[10px] text-on-surface-variant font-semibold">1h ago</time>
                              </div>
                              <p className="text-on-surface-variant text-xs mt-0.5">Internal Assessment Schedule published</p>
                            </div>
                          </div>

                          {/* Timeline Item 3 */}
                          <div className="relative flex gap-4 items-start">
                            <div className="w-10 h-10 rounded-full border border-outline-variant bg-white text-secondary flex items-center justify-center flex-shrink-0 z-10">
                              <span className="material-symbols-outlined text-[20px]">person_search</span>
                            </div>
                            <div className="flex-1">
                              <div className="flex justify-between items-baseline">
                                <span className="font-body-md text-body-md font-semibold text-on-surface">Faculty profile added</span>
                                <time className="text-[10px] text-on-surface-variant font-semibold">4h ago</time>
                              </div>
                              <p className="text-on-surface-variant text-xs mt-0.5">Dr. Sarah Jenkins added to Department of Arts</p>
                            </div>
                          </div>

                          {/* Timeline Item 4 */}
                          <div className="relative flex gap-4 items-start">
                            <div className="w-10 h-10 rounded-full border border-outline-variant bg-white text-secondary flex items-center justify-center flex-shrink-0 z-10">
                              <span className="material-symbols-outlined text-[20px]">settings_suggest</span>
                            </div>
                            <div className="flex-1">
                              <div className="flex justify-between items-baseline">
                                <span className="font-body-md text-body-md font-semibold text-on-surface">Update configured</span>
                                <time className="text-[10px] text-on-surface-variant font-semibold">1d ago</time>
                              </div>
                              <p className="text-on-surface-variant text-xs mt-0.5">Application update v1.0.1 successfully synced</p>
                            </div>
                          </div>

                        </div>
                        <div className="p-6 border-t border-outline-variant text-center">
                          <button onClick={() => setActiveTab('faculty')} className="text-secondary font-label-md text-label-md hover:underline font-bold cursor-pointer bg-transparent border-none">
                            View All Activity
                          </button>
                        </div>
                      </div>
                    </div>

                  </div>
                </div>
              )}

              {/* ============================== PAGE 4: APP UPDATES TAB ============================== */}
              {activeTab === 'app_updates' && (
                <div className="space-y-6">
                  {/* Page Header */}
                  <div>
                    <h3 className="font-headline-lg text-headline-lg text-on-surface mb-1">App Updates</h3>
                    <p className="font-body-lg text-body-lg text-on-surface-variant">Control application releases and notify students about new versions.</p>
                  </div>

                  <div className="grid grid-cols-12 gap-8 items-start">
                    {/* Left Column: Form & History */}
                    <div className="col-span-12 lg:col-span-8 space-y-6">
                      
                      {/* Current Status Banner */}
                      <div className="bg-white border border-outline-variant rounded-xl p-6 flex flex-wrap items-center justify-between gap-6 shadow-sm">
                        <div className="flex items-center gap-4">
                          <div className="w-12 h-12 bg-secondary/10 rounded-full flex items-center justify-center text-secondary">
                            <span className="material-symbols-outlined text-[28px]" style={{ fontVariationSettings: "'FILL' 1" }}>verified</span>
                          </div>
                          <div>
                            <h4 className="font-title-lg text-title-lg text-on-surface">Current Live Version {currentRelease.versionName}</h4>
                            <p className="text-on-surface-variant font-label-md text-label-md">Active for all students</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-8">
                          <div className="text-center">
                            <p className="text-on-surface-variant font-label-sm text-label-sm uppercase">Version Code</p>
                            <p className="font-headline-md text-headline-md text-on-surface">{currentRelease.versionCode}</p>
                          </div>
                          <div className="text-center">
                            <p className="text-on-surface-variant font-label-sm text-label-sm uppercase">Priority</p>
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-secondary/10 text-secondary">{currentRelease.priorityMode}</span>
                          </div>
                          <div className="text-center">
                            <p className="text-on-surface-variant font-label-sm text-label-sm uppercase">Status</p>
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">Published</span>
                          </div>
                        </div>
                      </div>

                      {/* Draft New Release Form */}
                      <div className="bg-white border border-outline-variant rounded-xl overflow-hidden shadow-sm">
                        <div className="px-6 py-4 border-b border-outline-variant flex items-center justify-between bg-surface">
                          <h4 className="font-headline-md text-headline-md text-on-surface">Draft New Release</h4>
                          <span className="material-symbols-outlined text-outline">info</span>
                        </div>
                        <form onSubmit={handlePublishUpdate} className="p-6 space-y-6">
                          
                          {/* Inputs Row */}
                          <div className="grid grid-cols-2 gap-6">
                            <div className="space-y-2">
                              <label className="font-label-md text-label-md text-on-surface-variant">Version Code</label>
                              <input 
                                type="number" 
                                value={appUpdateForm.versionCode}
                                onChange={(e) => setAppUpdateForm({ ...appUpdateForm, versionCode: e.target.value })}
                                className="w-full bg-white border border-outline rounded-lg px-4 py-2.5 focus:ring-2 focus:ring-secondary/20 focus:border-secondary outline-none transition-all" 
                                placeholder="e.g. 3" 
                                required
                              />
                            </div>
                            <div className="space-y-2">
                              <label className="font-label-md text-label-md text-on-surface-variant">Version Name</label>
                              <input 
                                type="text" 
                                value={appUpdateForm.versionName}
                                onChange={(e) => setAppUpdateForm({ ...appUpdateForm, versionName: e.target.value })}
                                className="w-full bg-white border border-outline rounded-lg px-4 py-2.5 focus:ring-2 focus:ring-secondary/20 focus:border-secondary outline-none transition-all" 
                                placeholder="e.g. 1.0.2" 
                                required
                              />
                            </div>
                          </div>

                          {/* Priority Selector */}
                          <div className="space-y-3">
                            <label className="font-label-md text-label-md text-on-surface-variant">Update Priority Mode</label>
                            <div className="grid grid-cols-2 gap-4">
                              <label 
                                className={`relative flex flex-col p-4 border rounded-xl cursor-pointer hover:border-error transition-all group ${
                                  appUpdateForm.priorityMode === 'Critical' 
                                    ? 'border-error bg-red-50/20' 
                                    : 'border-outline'
                                }`}
                              >
                                <input 
                                  type="radio" 
                                  name="priority" 
                                  checked={appUpdateForm.priorityMode === 'Critical'}
                                  onChange={() => setAppUpdateForm({ ...appUpdateForm, priorityMode: 'Critical' })}
                                  className="absolute top-4 right-4 text-error focus:ring-error h-4 w-4"
                                />
                                <span className="material-symbols-outlined text-error text-[32px] mb-2" style={{ fontVariationSettings: "'FILL' 1" }}>report</span>
                                <span className="font-title-lg text-title-lg text-on-surface">Critical Update</span>
                                <span className="text-on-surface-variant font-label-md text-label-md mt-1">Force users to update immediately. Students cannot bypass this screen.</span>
                              </label>

                              <label 
                                className={`relative flex flex-col p-4 border rounded-xl cursor-pointer hover:border-secondary transition-all group ${
                                  appUpdateForm.priorityMode === 'Flexible' 
                                    ? 'border-secondary bg-secondary/10' 
                                    : 'border-outline'
                                }`}
                              >
                                <input 
                                  type="radio" 
                                  name="priority" 
                                  checked={appUpdateForm.priorityMode === 'Flexible'}
                                  onChange={() => setAppUpdateForm({ ...appUpdateForm, priorityMode: 'Flexible' })}
                                  className="absolute top-4 right-4 text-secondary focus:ring-secondary h-4 w-4"
                                />
                                <span className="material-symbols-outlined text-secondary text-[32px] mb-2" style={{ fontVariationSettings: "'FILL' 1" }}>check_circle</span>
                                <span className="font-title-lg text-title-lg text-on-surface">Flexible Update</span>
                                <span className="text-on-surface-variant font-label-md text-label-md mt-1">Suggest an update. Students can choose to skip and continue using the app.</span>
                              </label>
                            </div>
                          </div>

                          {/* APK Download Url */}
                          <div className="space-y-2">
                            <label className="font-label-md text-label-md text-on-surface-variant">APK Download URL</label>
                            <div className="relative">
                              <span className="absolute left-4 top-1/2 -translate-y-1/2 material-symbols-outlined text-outline">link</span>
                              <input 
                                type="url" 
                                value={appUpdateForm.apkUrl}
                                onChange={(e) => setAppUpdateForm({ ...appUpdateForm, apkUrl: e.target.value })}
                                className="w-full bg-white border border-outline rounded-lg pl-11 pr-4 py-2.5 focus:ring-2 focus:ring-secondary/20 focus:border-secondary outline-none transition-all" 
                                required
                              />
                            </div>
                          </div>

                          {/* Release notes */}
                          <div className="space-y-2">
                            <label className="font-label-md text-label-md text-on-surface-variant">What's New?</label>
                            <textarea 
                              value={appUpdateForm.releaseNotes}
                              onChange={(e) => setAppUpdateForm({ ...appUpdateForm, releaseNotes: e.target.value })}
                              className="w-full bg-white border border-outline rounded-lg px-4 py-3 focus:ring-2 focus:ring-secondary/20 focus:border-secondary outline-none transition-all resize-none font-mono text-xs" 
                              rows="4" 
                              placeholder="e.g. • Added dark mode support"
                            />
                          </div>

                          {/* Form actions */}
                          <div className="pt-6 flex items-center justify-end gap-3 border-t border-outline-variant">
                            <button 
                              type="button" 
                              onClick={() => showToast("Draft saved successfully.")}
                              className="px-6 py-2.5 bg-white border border-outline-variant text-on-surface font-label-md text-label-md rounded-lg hover:bg-surface-container transition-all active:scale-95 cursor-pointer font-bold"
                            >
                              Save as Draft
                            </button>
                            <button 
                              type="submit"
                              className="px-8 py-2.5 bg-secondary text-white font-label-md text-label-md rounded-lg shadow-lg hover:bg-blue-700 transition-all active:scale-95 cursor-pointer font-bold"
                            >
                              Publish Update
                            </button>
                          </div>

                        </form>
                      </div>

                    </div>

                    {/* Right Column: Visual preview device */}
                    <div className="col-span-12 lg:col-span-4 sticky top-[84px] space-y-6">
                      
                      {/* Mobile phone frame */}
                      <div className="bg-surface-container p-8 rounded-2xl border border-outline-variant flex flex-col items-center shadow-sm">
                        <p className="font-label-sm text-label-sm uppercase text-on-surface-variant mb-6 tracking-widest">Student View Preview</p>
                        
                        <div className="relative w-[280px] h-[560px] bg-slate-900 rounded-[40px] border-[6px] border-slate-800 shadow-2xl overflow-hidden ring-1 ring-slate-400/20">
                          {/* Camera notch */}
                          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-6 bg-slate-800 rounded-b-2xl z-20"></div>
                          
                          {/* Faded feed background */}
                          <div className="absolute inset-0 bg-white p-4 filter blur-[2px] opacity-20">
                            <div className="w-full h-8 bg-surface-container rounded mb-4"></div>
                            <div className="grid grid-cols-2 gap-2 mb-4">
                              <div className="h-20 bg-surface-container rounded"></div>
                              <div className="h-20 bg-surface-container rounded"></div>
                            </div>
                            <div className="w-full h-32 bg-surface-container rounded"></div>
                          </div>

                          {/* Dialog Overlay */}
                          <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-xs flex items-end">
                            <div className="w-full bg-white rounded-t-[24px] p-6 space-y-4 shadow-xl transform transition-transform duration-500 translate-y-0">
                              <div className="w-12 h-12 bg-secondary/10 rounded-full flex items-center justify-center text-secondary">
                                <span className="material-symbols-outlined">system_update</span>
                              </div>
                              <div className="space-y-1">
                                <h5 className="text-on-surface font-headline-md text-headline-md">New Update Available</h5>
                                <p className="text-on-surface-variant font-label-md text-label-md">Version {appUpdateForm.versionName || '1.0.2'} is ready to download.</p>
                              </div>
                              <div className="bg-surface-container-low p-3 rounded-lg max-h-24 overflow-y-auto custom-scrollbar">
                                <p className="text-xs font-semibold text-on-surface mb-1">What's New:</p>
                                <p className="text-[10px] text-on-surface-variant whitespace-pre-line leading-relaxed">
                                  {appUpdateForm.releaseNotes || 'Performance improvements'}
                                </p>
                              </div>
                              <div className="flex flex-col gap-2 pt-2">
                                <button type="button" className="w-full py-2.5 bg-secondary text-white rounded-xl text-xs font-bold shadow-sm">Update Now</button>
                                {appUpdateForm.priorityMode === 'Flexible' && (
                                  <button type="button" className="w-full py-2 text-on-surface-variant text-xs font-medium bg-transparent border-none">Maybe Later</button>
                                )}
                              </div>
                            </div>
                          </div>

                          <div className="absolute bottom-1.5 left-1/2 -translate-x-1/2 w-24 h-1 bg-slate-800/20 rounded-full"></div>
                        </div>

                        <div className="mt-6 flex flex-col items-center gap-2">
                          <p className="text-on-surface-variant font-body-md text-body-md text-center">Simulating <strong>{appUpdateForm.priorityMode} Update</strong> behavior</p>
                          <button 
                            type="button"
                            onClick={() => setAppUpdateForm({ ...appUpdateForm, priorityMode: appUpdateForm.priorityMode === 'Critical' ? 'Flexible' : 'Critical' })}
                            className="text-secondary font-label-md text-label-md hover:underline font-bold cursor-pointer bg-transparent border-none"
                          >
                            Toggle Preview to {appUpdateForm.priorityMode === 'Critical' ? 'Flexible' : 'Critical'}
                          </button>
                        </div>
                      </div>

                      {/* Help Tip Card */}
                      <div className="p-6 bg-white border border-outline-variant rounded-xl flex items-start gap-4 shadow-sm">
                        <span className="material-symbols-outlined text-secondary bg-secondary/10 p-2 rounded-lg">lightbulb</span>
                        <div>
                          <p className="font-title-lg text-title-lg text-on-surface mb-1">Update Tips</p>
                          <p className="text-on-surface-variant font-body-md text-body-md leading-relaxed">
                            Critical updates should only be used for security patches or major infrastructure shifts that break older versions.
                          </p>
                        </div>
                      </div>

                    </div>
                  </div>
                </div>
              )}

              {/* ============================== PAGE 5: NOTICE BOARD TAB ============================== */}
              {activeTab === 'notice_board' && (
                <div className="space-y-6">
                  {/* Page Header */}
                  <div>
                    <h3 className="font-headline-lg text-headline-lg text-on-surface mb-1">Notice Board</h3>
                    <p className="font-body-lg text-body-lg text-on-surface-variant">Broadcast important information directly to the Campusly student mobile app.</p>
                  </div>

                  <div className="grid grid-cols-12 gap-8 items-start">
                    
                    {/* Left Column: Form & list */}
                    <div className="col-span-12 lg:col-span-7 space-y-6">
                      
                      {/* Notice Creator Card */}
                      <div className="bg-white border border-outline-variant rounded-xl p-8 shadow-sm">
                        <div className="flex items-center gap-3 mb-6">
                          <div className="w-10 h-10 rounded-full bg-secondary-container/10 flex items-center justify-center text-secondary">
                            <span className="material-symbols-outlined">edit_note</span>
                          </div>
                          <h4 className="font-title-lg text-title-lg text-on-surface">Create New Notice</h4>
                        </div>
                        
                        <form onSubmit={handlePublishNotice} className="space-y-6">
                          <div>
                            <label className="block text-label-md font-label-md text-on-surface-variant mb-2">Notice Title</label>
                            <input 
                              type="text" 
                              value={noticeForm.title}
                              onChange={(e) => setNoticeForm({ ...noticeForm, title: e.target.value })}
                              className="w-full bg-surface-container-low border border-outline-variant focus:border-secondary focus:ring-4 focus:ring-secondary/10 rounded-lg py-3 px-4 transition-all outline-none text-on-surface" 
                              placeholder="e.g. End of Semester Examination Schedule"
                              required
                            />
                          </div>

                          <div>
                            <label className="block text-label-md font-label-md text-on-surface-variant mb-2">Details</label>
                            <textarea 
                              value={noticeForm.details}
                              onChange={(e) => setNoticeForm({ ...noticeForm, details: e.target.value })}
                              className="w-full bg-surface-container-low border border-outline-variant focus:border-secondary focus:ring-4 focus:ring-secondary/10 rounded-lg py-3 px-4 transition-all outline-none text-on-surface resize-none" 
                              placeholder="Provide complete information here..."
                              rows="5"
                              required
                            />
                          </div>

                          {/* Priority switcher toggle */}
                          <div className="flex items-center justify-between p-4 bg-surface-container-low rounded-lg border border-outline-variant">
                            <div className="flex items-center gap-3">
                              <span className="material-symbols-outlined text-error">priority_high</span>
                              <div>
                                <p className="font-body-md font-semibold text-on-surface leading-snug">Mark as High Priority</p>
                                <p className="text-[10px] text-on-surface-variant">Sends a push notification and highlights the card</p>
                              </div>
                            </div>
                            <label className="relative inline-flex items-center cursor-pointer">
                              <input 
                                type="checkbox" 
                                checked={noticeForm.isHighPriority}
                                onChange={(e) => setNoticeForm({ ...noticeForm, isHighPriority: e.target.checked })}
                                className="sr-only peer"
                              />
                              <div className="w-11 h-6 bg-outline-variant peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-secondary"></div>
                            </label>
                          </div>

                          <button 
                            type="submit"
                            className="w-full bg-primary text-white font-title-lg text-title-lg py-4 rounded-lg hover:bg-secondary transition-all flex items-center justify-center gap-2 active:scale-[0.98] cursor-pointer font-bold border-none"
                          >
                            <span className="material-symbols-outlined">send</span>
                            Publish Notice
                          </button>
                        </form>
                      </div>

                      {/* Active Published Notices list */}
                      <div className="bg-white border border-outline-variant rounded-xl p-6 shadow-sm space-y-4">
                        <h4 className="font-title-lg text-title-lg text-on-surface pb-3 border-b border-outline-variant">Active Announcements ({announcements.length})</h4>
                        {announcements.length === 0 ? (
                          <p className="text-sm text-on-surface-variant py-4 text-center">No announcements published yet.</p>
                        ) : (
                          <div className="divide-y divide-slate-100">
                            {announcements.map((a) => (
                              <div key={a.id} className="py-4 flex justify-between gap-4 items-start">
                                <div className="space-y-1">
                                  <div className="flex items-center gap-2">
                                    <span className="font-semibold text-sm text-on-surface">{a.title}</span>
                                    {a.isHighPriority && (
                                      <span className="px-2 py-0.5 bg-red-100 text-red-800 text-[9px] font-bold uppercase rounded">High Priority</span>
                                    )}
                                  </div>
                                  <p className="text-xs text-on-surface-variant whitespace-pre-line leading-relaxed">{a.details}</p>
                                  <p className="text-[10px] text-outline font-semibold">Published: {a.timestamp?.seconds ? new Date(a.timestamp.seconds * 1000).toLocaleString() : 'Just now'}</p>
                                </div>
                                <button 
                                  onClick={() => handleDeleteNotice(a.id)}
                                  className="p-1.5 hover:bg-red-50 text-slate-400 hover:text-red-600 rounded transition-colors cursor-pointer bg-transparent border-none"
                                  title="Delete Notice"
                                >
                                  <span className="material-symbols-outlined text-[18px]">delete</span>
                                </button>
                              </div>
                            ))}
                          </div>
                        )}
                      </div>

                    </div>

                    {/* Right Column: Live Mobile preview */}
                    <div className="col-span-12 lg:col-span-5 flex flex-col items-center">
                      <p className="text-label-md font-label-md text-on-surface-variant mb-4 self-start">Live Mobile Preview</p>
                      
                      <div className="relative w-[300px] h-[600px] bg-slate-900 rounded-[3rem] border-[8px] border-slate-800 shadow-2xl overflow-hidden ring-1 ring-slate-400/20">
                        {/* Camera Notch */}
                        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-6 bg-slate-800 rounded-b-2xl z-20"></div>
                        
                        {/* Screen Content */}
                        <div className="absolute inset-0 bg-white overflow-hidden flex flex-col">
                          {/* Mobile Header */}
                          <div className="h-16 bg-white border-b border-gray-100 flex items-center px-6 pt-6 flex-shrink-0">
                            <span className="material-symbols-outlined text-gray-400">arrow_back</span>
                            <span className="ml-4 font-bold text-gray-800">Campus Hub</span>
                          </div>

                          {/* Mobile Feed */}
                          <div className="p-4 space-y-4 overflow-y-auto flex-1 custom-scrollbar">
                            <div className="flex justify-between items-center">
                              <span className="text-[10px] uppercase font-bold text-gray-400 tracking-wider">Latest Announcements</span>
                              <span className="text-[10px] text-secondary font-bold">See all</span>
                            </div>

                            {/* Simulated Notice Card */}
                            <div className={`p-4 rounded-xl border transition-all ${
                              noticeForm.isHighPriority 
                                ? 'bg-red-50/40 border-red-200 shadow-sm' 
                                : 'bg-gray-50 border-gray-100'
                            }`}>
                              <div className="flex items-center gap-2 mb-2">
                                <span className="material-symbols-outlined text-[16px] text-secondary">campaign</span>
                                <span className="font-bold text-xs text-gray-800 truncate flex-1">{noticeForm.title || 'Draft Notice Title'}</span>
                                {noticeForm.isHighPriority && (
                                  <span className="px-1.5 py-0.5 bg-red-100 text-red-800 text-[8px] font-extrabold rounded">URGENT</span>
                                )}
                              </div>
                              <p className="text-[10px] text-gray-600 leading-normal whitespace-pre-line line-clamp-4">
                                {noticeForm.details || 'Announcement details placeholder...'}
                              </p>
                              <div className="mt-3 pt-2 border-t border-gray-100 flex justify-between items-center">
                                <span className="text-[8px] text-gray-400">Published: Today</span>
                                <span className="text-[9px] text-secondary font-bold hover:underline cursor-pointer">Read Full Details</span>
                              </div>
                            </div>

                            {/* Other simulated static notices */}
                            <div className="p-4 rounded-xl border bg-gray-50 border-gray-100">
                              <div className="flex items-center gap-2 mb-2">
                                <span className="material-symbols-outlined text-[16px] text-secondary">campaign</span>
                                <span className="font-bold text-xs text-gray-800">Library Timings Revision</span>
                              </div>
                              <p className="text-[10px] text-gray-500 leading-normal">
                                Please note that the Central Library will remain open until 10:00 PM starting next semester.
                              </p>
                            </div>
                          </div>

                          <div className="absolute bottom-1.5 left-1/2 -translate-x-1/2 w-24 h-1 bg-slate-800/20 rounded-full"></div>
                        </div>

                      </div>
                    </div>

                  </div>
                </div>
              )}

              {/* ============================== PAGE 6: FACULTY DIRECTORY TAB ============================== */}
              {activeTab === 'faculty' && (
                <div className="space-y-6">
                  
                  {/* Page Header */}
                  <div className="flex justify-between items-end mb-8">
                    <div>
                      <h3 className="font-headline-lg text-headline-lg text-on-surface mb-1">Faculty Directory</h3>
                      <p className="font-body-md text-body-md text-on-surface-variant">Manage faculty profiles and cabin locations available to students.</p>
                    </div>
                    <button 
                      onClick={() => setModalType('add_faculty')}
                      className="bg-primary text-white px-6 py-2.5 rounded-lg flex items-center gap-2 font-semibold shadow-sm hover:opacity-90 active:scale-95 transition-all cursor-pointer text-sm font-bold border-none"
                    >
                      <span className="material-symbols-outlined text-[20px]">add</span>
                      <span>Add Faculty</span>
                    </button>
                  </div>

                  {/* Dashboard Stats / KPIs */}
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
                    <div className="bg-white border border-outline-variant p-5 rounded-xl shadow-sm">
                      <p className="font-label-md text-label-md text-on-surface-variant mb-1">Total Faculty</p>
                      <div className="flex items-end gap-2">
                        <span className="font-headline-lg text-headline-lg">{faculty.length > 0 ? faculty.length : '86'}</span>
                        <span className="font-label-md text-emerald-600 mb-1 flex items-center gap-0.5">
                          <span className="material-symbols-outlined text-[14px]">trending_up</span> 4.2%
                        </span>
                      </div>
                    </div>
                    <div className="bg-white border border-outline-variant p-5 rounded-xl shadow-sm">
                      <p className="font-label-md text-label-md text-on-surface-variant mb-1">Active Profiles</p>
                      <div className="flex items-end gap-2">
                        <span className="font-headline-lg text-headline-lg">{faculty.length > 0 ? faculty.length : '86'}</span>
                        <span className="text-on-surface-variant font-label-md mb-1">100%</span>
                      </div>
                    </div>
                    <div className="bg-white border border-outline-variant p-5 rounded-xl shadow-sm">
                      <p className="font-label-md text-label-md text-on-surface-variant mb-1">Pending Updates</p>
                      <div className="flex items-end gap-2">
                        <span className="font-headline-lg text-headline-lg">0</span>
                        <span className="text-on-surface-variant font-label-md mb-1">Synced</span>
                      </div>
                    </div>
                    <div className="bg-white border border-outline-variant p-5 rounded-xl shadow-sm">
                      <p className="font-label-md text-label-md text-on-surface-variant mb-1">Departments</p>
                      <div className="flex items-end gap-2">
                        <span className="font-headline-lg text-headline-lg">2</span>
                        <span className="text-on-surface-variant font-label-md mb-1">Global</span>
                      </div>
                    </div>
                  </div>

                  {/* UNIFIED SEARCH, FILTERS & TABLE CONTAINER CARD */}
                  <div className="bg-white border border-outline-variant rounded-xl overflow-hidden shadow-sm mb-8">
                    
                    {/* Filters header bar */}
                    <div className="px-6 py-4 border-b border-outline-variant bg-surface flex flex-wrap gap-4 items-center justify-between">
                      <div className="flex items-center gap-4 flex-1">
                        <div className="relative max-w-md w-full">
                          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-[20px]">search</span>
                          <input 
                            type="text" 
                            value={facultySearch}
                            onChange={(e) => setFacultySearch(e.target.value)}
                            placeholder="Search by name, email, or room..."
                            className="w-full pl-10 pr-4 py-2 border border-outline-variant rounded-lg focus:ring-2 focus:ring-secondary focus:border-secondary text-body-md transition-all outline-none bg-white"
                          />
                        </div>
                        <select 
                          value={facultyDeptFilter} 
                          onChange={(e) => setFacultyDeptFilter(e.target.value)}
                          className="border border-outline-variant rounded-lg px-4 py-2 text-body-md focus:ring-2 focus:ring-secondary focus:border-secondary bg-white outline-none text-xs font-semibold text-slate-700"
                        >
                          <option value="All">All Departments</option>
                          <option value="Computer Science">Computer Science</option>
                          <option value="Electrical Engineering">Electrical Engineering</option>
                        </select>
                      </div>
                    </div>

                    {/* Table area */}
                    <div className="overflow-x-auto">
                      <table className="w-full text-left border-collapse">
                        <thead>
                          <tr className="bg-slate-50 border-b border-outline-variant text-slate-500 font-bold text-xs uppercase tracking-wider">
                            <th className="px-6 py-4">Name</th>
                            <th className="px-6 py-4">Email</th>
                            <th className="px-6 py-4">Department</th>
                            <th className="px-6 py-4">Cabin</th>
                            <th className="px-6 py-4 text-right">Actions</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                          {filteredFaculty.map((f) => (
                            <tr key={f.id} className="hover:bg-slate-50/50 text-sm transition-colors text-slate-700">
                              <td className="px-6 py-4 font-bold text-slate-900">
                                <span 
                                  onClick={() => setSelectedFaculty(f)}
                                  className="hover:text-slate-900 hover:underline cursor-pointer"
                                >
                                  {f.name}
                                </span>
                              </td>
                              <td className="px-6 py-4">{f.email}</td>
                              <td className="px-6 py-4">{f.department}</td>
                              <td className="px-6 py-4 font-bold text-slate-800">{f.cabin}</td>
                              <td className="px-6 py-4 text-right space-x-2">
                                <button 
                                  onClick={() => setSelectedFaculty(f)}
                                  className="px-2.5 py-1 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded text-xs font-bold text-slate-700 transition-colors cursor-pointer font-bold"
                                >
                                  View
                                </button>
                                <button 
                                  onClick={() => {
                                    setConfirmDialog({
                                      type: 'delete_faculty',
                                      message: 'Are you sure you want to delete this faculty profile?',
                                      action: () => handleDeleteFaculty(f.id),
                                      data: f
                                    });
                                  }}
                                  className="px-2.5 py-1 bg-red-50 hover:bg-red-100 border border-red-100 rounded text-xs font-bold text-red-700 transition-colors cursor-pointer font-bold border-none"
                                >
                                  Delete
                                </button>
                              </td>
                            </tr>
                          ))}
                          {filteredFaculty.length === 0 && (
                            <tr>
                              <td colSpan={5} className="px-6 py-12 text-center text-slate-400 font-semibold">
                                No faculty found.
                              </td>
                            </tr>
                          )}
                        </tbody>
                      </table>
                    </div>
                  </div>

                  {/* FACULTY PROFILE VIEW PANEL DRAWER */}
                  {selectedFaculty && (
                    <div className="fixed inset-y-0 right-0 w-96 bg-white border-l border-outline-variant z-40 p-8 shadow-2xl flex flex-col justify-between animate-slide-in">
                      <div className="space-y-6">
                        <div className="flex justify-between items-center pb-4 border-b border-outline-variant">
                          <h2 className="text-lg font-bold text-slate-900">Faculty Details</h2>
                          <button 
                            onClick={() => setSelectedFaculty(null)}
                            className="p-1 hover:bg-slate-100 rounded text-slate-400 hover:text-slate-600 cursor-pointer bg-transparent border-none"
                          >
                            <span className="material-symbols-outlined">close</span>
                          </button>
                        </div>

                        <div className="space-y-4">
                          <div>
                            <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Personal Information</h4>
                            <div className="bg-slate-50 rounded-lg p-4 space-y-2 border border-slate-100">
                              <p className="text-sm font-semibold text-slate-500">Name: <strong className="text-slate-800">{selectedFaculty.name}</strong></p>
                              <p className="text-sm font-semibold text-slate-500">Email: <strong className="text-slate-800">{selectedFaculty.email}</strong></p>
                            </div>
                          </div>

                          <div>
                            <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Institutional Details</h4>
                            <div className="bg-slate-50 rounded-lg p-4 space-y-2 border border-slate-100">
                              <p className="text-sm font-semibold text-slate-500">Department: <strong className="text-slate-800">{selectedFaculty.department}</strong></p>
                              <p className="text-sm font-semibold text-slate-500">Cabin Location: <strong className="text-slate-800">{selectedFaculty.cabin}</strong></p>
                            </div>
                          </div>
                        </div>
                      </div>

                      <div className="pt-6 border-t border-outline-variant">
                        <button 
                          onClick={() => {
                            setConfirmDialog({
                              type: 'delete_faculty',
                              message: 'Are you sure you want to delete this faculty profile?',
                              action: () => handleDeleteFaculty(selectedFaculty.id),
                              data: selectedFaculty
                            });
                          }}
                          className="w-full py-3 bg-red-50 hover:bg-red-100 text-red-700 font-bold text-xs rounded-lg border border-red-100 transition-colors cursor-pointer text-center font-bold border-none"
                        >
                          Delete Faculty Profile
                        </button>
                      </div>

                    </div>
                  )}

                </div>
              )}

            </div>
          )}

        </div>
      </main>

      {/* ========================================================================= */}
      {/* ============================== INTERACTIVE MODALS ======================== */}
      {/* ========================================================================= */}

      {/* 1. Add Faculty Modal */}
      {modalType === 'add_faculty' && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
          <div className="bg-white border border-outline-variant rounded-xl p-6 w-full max-w-[400px] shadow-xl space-y-6">
            <div className="flex justify-between items-center border-b border-outline-variant pb-3">
              <h3 className="text-base font-bold text-slate-900">Add Faculty</h3>
              <button onClick={() => setModalType(null)} className="text-slate-400 hover:text-slate-600 cursor-pointer bg-transparent border-none">
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>
            <form onSubmit={handleAddFaculty} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Full Name</label>
                <input 
                  type="text" 
                  value={facultyForm.name}
                  onChange={(e) => setFacultyForm({ ...facultyForm, name: e.target.value })}
                  placeholder="e.g. Dr. Sarah Jenkins"
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-outline-variant rounded-lg text-sm text-primary placeholder-slate-400 focus:outline-none focus:border-secondary focus:bg-white transition-all"
                  required
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Email Address</label>
                <input 
                  type="email" 
                  value={facultyForm.email}
                  onChange={(e) => setFacultyForm({ ...facultyForm, email: e.target.value })}
                  placeholder="e.g. sarah.j@campusly.edu"
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-outline-variant rounded-lg text-sm text-primary placeholder-slate-400 focus:outline-none focus:border-secondary focus:bg-white transition-all"
                  required
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Department</label>
                <select 
                  value={facultyForm.department}
                  onChange={(e) => setFacultyForm({ ...facultyForm, department: e.target.value })}
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-outline-variant rounded-lg text-sm text-primary focus:outline-none focus:border-secondary focus:bg-white transition-all"
                >
                  <option value="Computer Science">Computer Science</option>
                  <option value="Electrical Engineering">Electrical Engineering</option>
                </select>
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Cabin / Room Location</label>
                <input 
                  type="text" 
                  value={facultyForm.cabin}
                  onChange={(e) => setFacultyForm({ ...facultyForm, cabin: e.target.value })}
                  placeholder="e.g. Block A, Room 302"
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-outline-variant rounded-lg text-sm text-primary placeholder-slate-400 focus:outline-none focus:border-secondary focus:bg-white transition-all"
                  required
                />
              </div>
              <div className="pt-4 flex items-center justify-end gap-2.5">
                <button 
                  type="button" 
                  onClick={() => setModalType(null)}
                  className="py-2.5 px-4 bg-white hover:bg-slate-50 border border-outline-variant text-slate-700 font-bold text-xs rounded-lg transition-colors cursor-pointer border-none"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="py-2.5 px-6 bg-primary hover:bg-slate-800 text-white font-bold text-xs rounded-lg transition-colors cursor-pointer font-bold border-none"
                >
                  Add Faculty
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Confirmation Prompt Dialog Modal */}
      {confirmDialog && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
          <div className="bg-white border border-outline-variant rounded-xl p-6 w-full max-w-[360px] shadow-xl space-y-4 text-center">
            <div className="w-12 h-12 rounded-full bg-red-50 text-red-600 flex items-center justify-center mx-auto border border-red-100">
              <span className="material-symbols-outlined text-[24px]">warning</span>
            </div>
            <div className="space-y-1">
              <h4 className="text-sm font-bold text-slate-900">Confirm Operation</h4>
              <p className="text-xs text-slate-500 leading-normal">{confirmDialog.message}</p>
            </div>
            <div className="flex gap-2.5 pt-2">
              <button 
                onClick={() => setConfirmDialog(null)}
                className="flex-1 py-2 px-3 bg-white hover:bg-slate-50 border border-outline-variant text-slate-700 font-bold text-xs rounded-lg transition-colors cursor-pointer border-none"
              >
                No, Cancel
              </button>
              <button 
                onClick={confirmDialog.action}
                className="flex-1 py-2 px-3 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-lg transition-colors cursor-pointer font-bold border-none"
              >
                Yes, Confirm
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Toast popup */}
      {toast && (
        <div className="fixed bottom-6 right-6 bg-slate-900 text-white py-3 px-5 rounded-lg text-xs font-bold shadow-lg flex items-center gap-2 animate-slide-in z-50">
          <span className="material-symbols-outlined text-[16px] text-emerald-400">check_circle</span>
          <span>{toast}</span>
        </div>
      )}

    </div>
  );
}
