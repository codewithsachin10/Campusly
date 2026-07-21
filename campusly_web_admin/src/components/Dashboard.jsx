import React, { useState, useEffect } from 'react';
import { signOut } from 'firebase/auth';
import { 
  collection, 
  doc, 
  setDoc, 
  getDocs, 
  addDoc, 
  deleteDoc, 
  onSnapshot 
} from 'firebase/firestore';
import { auth, db } from '../firebase';

export default function Dashboard({ user, onLogout }) {
  const [activeTab, setActiveTab] = useState('overview');
  const [activeModal, setActiveModal] = useState(null);
  const [loading, setLoading] = useState(false);
  const [statusMsg, setStatusMsg] = useState({ type: '', text: '' });
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedDept, setSelectedDept] = useState('All Departments');

  // Stats
  const [stats, setStats] = useState({
    usersCount: 0,
    noticesCount: 0,
    facultyCount: 0
  });

  // 1. App Updates Config
  const [updatesConfig, setUpdatesConfig] = useState({
    latestVersionCode: 1,
    latestVersionName: '1.0.0',
    critical: false,
    apkUrl: '',
    releaseNotes: ''
  });

  // Draft updates fields
  const [draftConfig, setDraftConfig] = useState({
    latestVersionCode: 1,
    latestVersionName: '1.0.0',
    critical: false,
    apkUrl: '',
    releaseNotes: ''
  });

  // 2. Announcements notices
  const [notices, setNotices] = useState([]);
  const [newNotice, setNewNotice] = useState({
    title: '',
    message: '',
    highPriority: false
  });

  // 3. Faculty Cabin Directory
  const [faculties, setFaculties] = useState([]);
  const [newFaculty, setNewFaculty] = useState({
    name: '',
    email: '',
    department: 'Computer Science',
    cabin: '',
    role: 'Senior Professor'
  });

  // Status message utility
  const triggerStatus = (type, text) => {
    setStatusMsg({ type, text });
    setTimeout(() => setStatusMsg({ type: '', text: '' }), 4000);
  };

  // Setup Firestore Real-time Listeners
  useEffect(() => {
    // 1. Updates configuration
    const unsubUpdates = onSnapshot(doc(db, 'app_config', 'update'), (snap) => {
      if (snap.exists()) {
        const data = snap.data();
        setUpdatesConfig(data);
        setDraftConfig(data);
      }
    });

    // 2. Announcements notice board
    const unsubNotices = onSnapshot(collection(db, 'announcements'), (snap) => {
      const list = [];
      snap.forEach(d => list.push({ id: d.id, ...d.data() }));
      list.sort((a, b) => (b.timestamp?.seconds || 0) - (a.timestamp?.seconds || 0));
      setNotices(list);
      setStats(prev => ({ ...prev, noticesCount: list.length }));
    });

    // 3. Faculty cabin directory
    const unsubFaculty = onSnapshot(collection(db, 'faculties'), (snap) => {
      const list = [];
      snap.forEach(d => list.push({ id: d.id, ...d.data() }));
      list.sort((a, b) => a.name.localeCompare(b.name));
      setFaculties(list);
      setStats(prev => ({ ...prev, facultyCount: list.length }));
    });

    // 4. One-time fetch of users count
    getDocs(collection(db, 'users')).then(snap => {
      setStats(prev => ({ ...prev, usersCount: snap.size }));
    }).catch(e => console.error("Error fetching users size:", e));

    return () => {
      unsubUpdates();
      unsubNotices();
      unsubFaculty();
    };
  }, []);

  // Save updates configuration
  const handleSaveUpdates = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await setDoc(doc(db, 'app_config', 'update'), {
        ...draftConfig,
        latestVersionCode: parseInt(draftConfig.latestVersionCode) || 1,
        updatedAt: new Date()
      }, { merge: true });
      triggerStatus('success', 'App update release settings published live!');
    } catch (err) {
      console.error(err);
      triggerStatus('error', 'Error publishing update config.');
    } finally {
      setLoading(false);
    }
  };

  // Add Notice
  const handlePostNotice = async (e) => {
    e.preventDefault();
    if (!newNotice.title || !newNotice.message) return;
    setLoading(true);
    try {
      await addDoc(collection(db, 'announcements'), {
        title: newNotice.title,
        message: newNotice.message,
        highPriority: newNotice.highPriority,
        author: 'System Admin',
        timestamp: new Date()
      });
      setNewNotice({ title: '', message: '', highPriority: false });
      triggerStatus('success', 'Announcement broadcasted successfully!');
    } catch (err) {
      console.error(err);
      triggerStatus('error', 'Error broadcasting announcement.');
    } finally {
      setLoading(false);
    }
  };

  // Delete Notice
  const handleDeleteNotice = async (id) => {
    if (!window.confirm('Delete this notice? It will instantly disappear from all student devices.')) return;
    try {
      await deleteDoc(doc(db, 'announcements', id));
      triggerStatus('success', 'Notice deleted successfully.');
    } catch (err) {
      console.error(err);
      triggerStatus('error', 'Failed to delete notice.');
    }
  };

  // Add Faculty
  const handleAddFaculty = async (e) => {
    e.preventDefault();
    if (!newFaculty.name || !newFaculty.cabin) return;
    setLoading(true);
    try {
      await addDoc(collection(db, 'faculties'), {
        name: newFaculty.name,
        email: newFaculty.email || 'faculty@college.edu',
        department: newFaculty.department,
        cabin: newFaculty.cabin,
        role: newFaculty.role
      });
      setNewFaculty({
        name: '',
        email: '',
        department: 'Computer Science',
        cabin: '',
        role: 'Senior Professor'
      });
      triggerStatus('success', 'Faculty added to directory.');
    } catch (err) {
      console.error(err);
      triggerStatus('error', 'Failed to add faculty.');
    } finally {
      setLoading(false);
    }
  };

  // Delete Faculty
  const handleDeleteFaculty = async (id) => {
    if (!window.confirm('Remove this faculty member from directory?')) return;
    try {
      await deleteDoc(doc(db, 'faculties', id));
      triggerStatus('success', 'Faculty member removed.');
    } catch (err) {
      console.error(err);
      triggerStatus('error', 'Failed to remove faculty.');
    }
  };

  // Filtered faculty list
  const filteredFaculties = faculties.filter((f) => {
    const matchesSearch = 
      f.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      f.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
      f.cabin.toLowerCase().includes(searchQuery.toLowerCase());
    
    const matchesDept = 
      selectedDept === 'All Departments' || 
      f.department === selectedDept;

    return matchesSearch && matchesDept;
  });

  return (
    <div className="min-h-screen bg-background">
      {/* Toast Alert popup */}
      {statusMsg.text && (
        <div className="fixed top-4 right-4 z-[9999] bg-white border border-outline-variant shadow-lg rounded-xl p-4 flex items-center gap-3 border-l-4 border-l-secondary animate-bounce">
          <span className="material-symbols-outlined text-secondary" style={{ fontVariationSettings: "'FILL' 1" }}>
            {statusMsg.type === 'success' ? 'check_circle' : 'error'}
          </span>
          <span className="font-semibold text-on-surface text-body-md">{statusMsg.text}</span>
        </div>
      )}

      {/* Top App Bar Header */}
      <header className="fixed top-0 left-0 right-0 h-16 bg-surface border-b border-outline-variant px-[32px] flex justify-between items-center z-40">
        <div className="flex items-center gap-4">
          {activeTab !== 'overview' && (
            <button 
              onClick={() => setActiveTab('overview')}
              className="flex items-center gap-2 px-3 py-1.5 border border-outline-variant bg-white rounded-full text-label-md font-bold text-on-surface hover:bg-surface-container transition-all cursor-pointer mr-2 active:scale-95"
            >
              <span className="material-symbols-outlined text-[18px]">arrow_back</span>
              Console Hub
            </button>
          )}
          <h2 className="font-headline-md text-headline-md font-bold text-on-surface uppercase tracking-tight">
            {activeTab === 'overview' && 'Campusly Control Center'}
            {activeTab === 'updates' && 'App Updates'}
            {activeTab === 'notices' && 'Notice Board'}
            {activeTab === 'faculty' && 'Faculty Directory'}
          </h2>
        </div>
        <div className="flex items-center gap-6">
          <button 
            onClick={onLogout}
            className="flex items-center gap-2 px-3 py-1.5 border border-error/30 text-error rounded-lg text-label-md hover:bg-error-container/20 transition-all cursor-pointer active:scale-95 font-semibold"
          >
            <span className="material-symbols-outlined text-[18px]">logout</span>
            Logout
          </button>
          <div className="w-10 h-10 rounded-full border-2 border-outline-variant bg-surface-container overflow-hidden">
            <img 
              className="w-full h-full object-cover" 
              alt="Profile" 
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuDjz2d_94z8c_Tkr5uExR2VoOMC2rNpJO56RzTX4UGNCEfDFer_eXghCdv2C66kw86IFIbKv6XM-5rV-v0tu96H5fyuMsGZt2lHfnwgAc41NwbltC4Q6yrYcun3jL5GjNtiqEaH0ZkAfVGSj1xoTitYVR7xI3anNfvmyAn_YCQ-ysqB0RLao-_-6HjtkwhNb19eEWlPPR2snwBTeEbtRv4ocuWysZEJDswj8qrsGtgqla0Js8n0eGmnXKE2soMuxa6EpfwIqv5riIn_"
            />
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className={`pt-16 ${activeTab === 'overview' ? 'h-screen overflow-hidden' : 'min-h-screen'}`}>
        <div className="p-[32px] max-w-[1440px] mx-auto">
          <div className={`bg-surface-container-lowest border border-outline-variant rounded-2xl p-8 shadow-soft ${
            activeTab === 'overview' 
              ? 'h-[calc(100vh-128px)] overflow-hidden flex flex-col justify-center space-y-8' 
              : 'min-h-[calc(100vh-128px)] space-y-6'
          }`}>
          
          {/* ==================== OVERVIEW TAB (Centered Console Hub) ==================== */}
          {activeTab === 'overview' && (
            <div className="space-y-10 animate-fade-in py-4">
              {/* Header Branding */}
              <div className="text-center space-y-3">
                <h1 className="font-brand text-headline-lg font-black text-on-surface tracking-tight flex items-center justify-center gap-2">
                  <span className="material-symbols-outlined text-secondary text-[32px]">school</span>
                  Campusly Control Center
                </h1>
                <p className="text-on-surface-variant font-label-md text-label-md max-w-md mx-auto leading-none">
                  Select a console module below to manage your college application settings.
                </p>
                
                {/* Stats Pill Badges Row */}
                <div className="flex flex-wrap justify-center gap-3 text-label-sm font-label-sm text-on-surface-variant pt-2">
                  <span className="px-3 py-1 bg-surface-container-low border border-outline-variant/40 rounded-full flex items-center gap-1.5 shadow-sm">
                    <span className="w-1.5 h-1.5 rounded-full bg-secondary"></span>
                    Students: <strong>{stats.usersCount}</strong>
                  </span>
                  <span className="px-3 py-1 bg-surface-container-low border border-outline-variant/40 rounded-full flex items-center gap-1.5 shadow-sm">
                    <span className="w-1.5 h-1.5 rounded-full bg-secondary"></span>
                    Active Notices: <strong>{stats.noticesCount}</strong>
                  </span>
                  <span className="px-3 py-1 bg-surface-container-low border border-outline-variant/40 rounded-full flex items-center gap-1.5 shadow-sm">
                    <span className="w-1.5 h-1.5 rounded-full bg-secondary"></span>
                    Faculty: <strong>{stats.facultyCount}</strong>
                  </span>
                  <span className="px-3 py-1 bg-surface-container-low border border-outline-variant/40 rounded-full flex items-center gap-1.5 shadow-sm">
                    <span className="w-1.5 h-1.5 rounded-full bg-secondary"></span>
                    Live Version: <strong>v{updatesConfig.latestVersionName}</strong>
                  </span>
                </div>
              </div>

              {/* 3-Column Uniform Grid Layout */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-[1280px] mx-auto items-start">
                
                {/* COLUMN 1: CAMPUS & ANALYTICS */}
                <div className="space-y-8">
                  {/* Category: CAMPUS */}
                  <div className="space-y-3">
                    <h3 className="font-bold text-label-sm text-outline uppercase tracking-wider flex items-center gap-2 border-b border-outline-variant/30 pb-2">
                      <span>🏫</span> CAMPUS
                    </h3>
                    <div className="space-y-3">
                      <div 
                        onClick={() => setActiveModal('Students')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">person</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">Students</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Enrolled student accounts</p>
                        </div>
                      </div>

                      <div 
                        onClick={() => setActiveModal('Departments & Classes')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">account_balance</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">Departments & Classes</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Configure branches & batches</p>
                        </div>
                      </div>

                      <div 
                        onClick={() => setActiveTab('faculty')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">group</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">Faculty Directory</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Cabin office mappings</p>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Category: ANALYTICS */}
                  <div className="space-y-3">
                    <h3 className="font-bold text-label-sm text-outline uppercase tracking-wider flex items-center gap-2 border-b border-outline-variant/30 pb-2">
                      <span>📈</span> ANALYTICS
                    </h3>
                    <div className="space-y-3">
                      <div 
                        onClick={() => setActiveModal('Usage Analytics')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">analytics</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">Usage Analytics</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Student app usage charts</p>
                        </div>
                      </div>

                      <div 
                        onClick={() => setActiveModal('Device & App Analytics')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">device_hub</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">Device & App Analytics</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Platform performance stats</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* COLUMN 2: ACADEMICS & SUPPORT */}
                <div className="space-y-8">
                  {/* Category: ACADEMICS */}
                  <div className="space-y-3">
                    <h3 className="font-bold text-label-sm text-outline uppercase tracking-wider flex items-center gap-2 border-b border-outline-variant/30 pb-2">
                      <span>📚</span> ACADEMICS
                    </h3>
                    <div className="space-y-3">
                      <div 
                        onClick={() => setActiveModal('Timetable')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">calendar_month</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">Timetable</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Schedules & slot configurations</p>
                        </div>
                      </div>

                      <div 
                        onClick={() => setActiveModal('Attendance')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">how_to_reg</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">Attendance</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Logs & absence percentages</p>
                        </div>
                      </div>

                      <div 
                        onClick={() => setActiveModal('Assignments')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">assignment</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">Assignments</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Submission deadlines & details</p>
                        </div>
                      </div>

                      <div 
                        onClick={() => setActiveModal('Exams')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">menu_book</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">Exams</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Rosters & mid-sem dates</p>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Category: SUPPORT */}
                  <div className="space-y-3">
                    <h3 className="font-bold text-label-sm text-outline uppercase tracking-wider flex items-center gap-2 border-b border-outline-variant/30 pb-2">
                      <span>🛠️</span> SUPPORT
                    </h3>
                    <div className="space-y-3">
                      <div 
                        onClick={() => setActiveModal('Support Center')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">contact_support</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">Support Center</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Helpdesk & query tickets</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* COLUMN 3: ACTIVITIES & SYSTEM */}
                <div className="space-y-8">
                  {/* Category: CAMPUS ACTIVITIES */}
                  <div className="space-y-3">
                    <h3 className="font-bold text-label-sm text-outline uppercase tracking-wider flex items-center gap-2 border-b border-outline-variant/30 pb-2">
                      <span>🌐</span> CAMPUS ACTIVITIES
                    </h3>
                    <div className="space-y-3">
                      <div 
                        onClick={() => setActiveModal('Events & Activities')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">local_activity</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">Events & Activities</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Fest schedules & culture board</p>
                        </div>
                      </div>

                      <div 
                        onClick={() => setActiveTab('notices')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">campaign</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">Notifications</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Live announcements board</p>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Category: SYSTEM */}
                  <div className="space-y-3">
                    <h3 className="font-bold text-label-sm text-outline uppercase tracking-wider flex items-center gap-2 border-b border-outline-variant/30 pb-2">
                      <span>⚙️</span> SYSTEM
                    </h3>
                    <div className="space-y-3">
                      <div 
                        onClick={() => setActiveTab('updates')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">system_update</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">App Updates</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Release config settings</p>
                        </div>
                      </div>

                      <div 
                        onClick={() => setActiveModal('Campus Configuration')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">settings_applications</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">Campus Config</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Global app config variables</p>
                        </div>
                      </div>

                      <div 
                        onClick={() => setActiveModal('Feature Flags')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">toggle_on</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">Feature Flags</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Toggle live features & beta flags</p>
                        </div>
                      </div>

                      <div 
                        onClick={() => setActiveModal('Audit Logs')}
                        className="flex items-center gap-3 p-4 bg-white border border-outline-variant/60 rounded-xl hover:border-secondary hover:bg-surface-bright active:scale-[0.98] transition-all cursor-pointer shadow-sm group h-[76px]"
                      >
                        <div className="w-10 h-10 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary group-hover:bg-secondary group-hover:text-white transition-colors duration-200 flex-shrink-0">
                          <span className="material-symbols-outlined text-[20px]">history_toggle_off</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-body-md text-on-surface truncate">Audit Logs</p>
                          <p className="text-[11px] text-on-surface-variant/75 truncate mt-0.5">Access history logs</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

              </div>
            </div>
          )}

          {/* ==================== APP UPDATES TAB ==================== */}
          {activeTab === 'updates' && (
            <div className="space-y-6">
              <div className="mb-4">
                <p className="text-on-surface-variant font-body-lg text-body-lg">Control application releases and notify students about new versions.</p>
              </div>

              <div className="grid grid-cols-12 gap-8">
                {/* Form parameters */}
                <div className="col-span-12 lg:col-span-7 space-y-6">
                  {/* Status header */}
                  <div className="bg-white border border-outline-variant rounded-xl p-6 flex flex-wrap items-center justify-between gap-6 shadow-sm">
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 bg-secondary-container/10 rounded-full flex items-center justify-center">
                        <span className="material-symbols-outlined text-secondary" style={{ fontVariationSettings: "'FILL' 1" }}>verified</span>
                      </div>
                      <div>
                        <h4 className="font-title-lg text-title-lg text-on-surface font-bold">Current Live: v{updatesConfig.latestVersionName}</h4>
                        <p className="text-on-surface-variant font-label-md text-label-md">Status: Published</p>
                      </div>
                    </div>
                    <div className="flex gap-6">
                      <div className="text-center">
                        <p className="text-on-surface-variant font-label-sm text-label-sm uppercase">Build Code</p>
                        <p className="font-headline-md text-headline-md text-on-surface font-bold">{updatesConfig.latestVersionCode}</p>
                      </div>
                      <div className="text-center">
                        <p className="text-on-surface-variant font-label-sm text-label-sm uppercase">Type</p>
                        <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold ${updatesConfig.critical ? 'bg-red-100 text-red-800' : 'bg-blue-100 text-blue-800'}`}>
                          {updatesConfig.critical ? 'Mandatory' : 'Flexible'}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Form */}
                  <form onSubmit={handleSaveUpdates} className="bg-white border border-outline-variant rounded-xl overflow-hidden shadow-sm p-6 space-y-6">
                    <h4 className="font-headline-md text-headline-md text-on-surface font-bold">Draft New Release</h4>
                    
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <label className="font-label-md text-label-md text-on-surface-variant block font-bold">Version Code (Build number)</label>
                        <input 
                          type="number"
                          value={draftConfig.latestVersionCode}
                          onChange={(e) => setDraftConfig({ ...draftConfig, latestVersionCode: e.target.value })}
                          className="w-full bg-white border border-outline-variant rounded-lg px-4 py-2.5 focus:ring-2 focus:ring-secondary focus:border-secondary outline-none text-on-surface"
                          required
                        />
                      </div>
                      <div className="space-y-2">
                        <label className="font-label-md text-label-md text-on-surface-variant block font-bold">Version Name (e.g. 1.0.2)</label>
                        <input 
                          type="text"
                          value={draftConfig.latestVersionName}
                          onChange={(e) => setDraftConfig({ ...draftConfig, latestVersionName: e.target.value })}
                          className="w-full bg-white border border-outline-variant rounded-lg px-4 py-2.5 focus:ring-2 focus:ring-secondary focus:border-secondary outline-none text-on-surface"
                          required
                        />
                      </div>
                    </div>

                    <div className="space-y-3">
                      <label className="font-label-md text-label-md text-on-surface-variant block font-bold">Update Priority Mode</label>
                      <div className="grid grid-cols-2 gap-4">
                        <div 
                          onClick={() => setDraftConfig({ ...draftConfig, critical: false })}
                          className={`p-4 border rounded-xl cursor-pointer transition-all flex flex-col justify-between h-28 ${
                            !draftConfig.critical 
                              ? 'border-secondary bg-surface-container-low/50 text-secondary' 
                              : 'border-outline-variant hover:border-outline'
                          }`}
                        >
                          <span className="material-symbols-outlined text-[24px]">info</span>
                          <div>
                            <p className="font-semibold text-body-md text-on-surface">Flexible Update</p>
                            <p className="text-[11px] text-on-surface-variant">Recommended. Background download and restart toast.</p>
                          </div>
                        </div>
                        <div 
                          onClick={() => setDraftConfig({ ...draftConfig, critical: true })}
                          className={`p-4 border rounded-xl cursor-pointer transition-all flex flex-col justify-between h-28 ${
                            draftConfig.critical 
                              ? 'border-error bg-red-50/50 text-error' 
                              : 'border-outline-variant hover:border-outline'
                          }`}
                        >
                          <span className="material-symbols-outlined text-[24px]">warning</span>
                          <div>
                            <p className="font-semibold text-body-md text-on-surface">Critical Update</p>
                            <p className="text-[11px] text-on-surface-variant">Blocking overlay prompt. Forces immediate downloads.</p>
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="space-y-2">
                      <label className="font-label-md text-label-md text-on-surface-variant block font-bold">Direct APK Download URL</label>
                      <input 
                        type="url"
                        value={draftConfig.apkUrl}
                        onChange={(e) => setDraftConfig({ ...draftConfig, apkUrl: e.target.value })}
                        className="w-full bg-white border border-outline-variant rounded-lg px-4 py-2.5 focus:ring-2 focus:ring-secondary focus:border-secondary outline-none text-on-surface"
                        placeholder="https://github.com/..."
                        required
                      />
                    </div>

                    <div className="space-y-2">
                      <label className="font-label-md text-label-md text-on-surface-variant block font-bold">Release Notes / Changelog</label>
                      <textarea 
                        value={draftConfig.releaseNotes}
                        onChange={(e) => setDraftConfig({ ...draftConfig, releaseNotes: e.target.value })}
                        className="w-full bg-white border border-outline-variant rounded-lg px-4 py-2.5 focus:ring-2 focus:ring-secondary focus:border-secondary outline-none text-on-surface resize-none"
                        rows={4}
                        placeholder="Bugs fixed..."
                      />
                    </div>

                    <button 
                      type="submit" 
                      className="w-full bg-primary text-on-primary py-3.5 rounded-lg font-bold hover:bg-secondary active:scale-95 transition-all flex items-center justify-center gap-2 cursor-pointer"
                    >
                      <span className="material-symbols-outlined">send</span>
                      Publish Release Settings
                    </button>
                  </form>
                </div>

                {/* Mobile Preview Device */}
                <div className="col-span-12 lg:col-span-5 flex flex-col items-center">
                  <p className="text-label-md font-label-md text-on-surface-variant mb-4 self-start">Live Mobile Preview</p>
                  
                  {/* Phone Shell */}
                  <div className="relative w-[300px] h-[600px] bg-slate-900 rounded-[3rem] border-[8px] border-slate-800 shadow-2xl overflow-hidden">
                    <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-6 bg-slate-800 rounded-b-2xl z-20"></div>
                    <div className="absolute inset-0 bg-white overflow-hidden flex flex-col pt-6 px-4">
                      
                      {/* Fake Home content */}
                      <div className="h-16 flex items-center gap-3 border-b border-slate-100 mb-4">
                        <div className="w-10 h-10 rounded-lg bg-secondary/15 flex items-center justify-center text-secondary">
                          <span className="material-symbols-outlined">school</span>
                        </div>
                        <div>
                          <p className="font-bold text-[14px] text-slate-800">Campusly</p>
                          <p className="text-[10px] text-slate-400">Class timetable</p>
                        </div>
                      </div>
                      <div className="h-20 bg-slate-50 border border-slate-100 rounded-xl mb-4"></div>
                      
                      {/* Critical Update Prompt Overlay (if critical is toggled in draft config) */}
                      {draftConfig.critical && (
                        <div className="absolute inset-0 bg-black/60 z-50 flex items-end">
                          <div className="w-full bg-white rounded-t-3xl p-6 space-y-4 animate-slide-up">
                            <div className="flex items-center gap-3 text-error">
                              <span className="material-symbols-outlined" style={{ fontVariationSettings: "'FILL' 1" }}>gpp_maybe</span>
                              <h5 className="font-bold text-body-lg text-on-surface">Mandatory Update</h5>
                            </div>
                            <p className="text-[12px] text-on-surface-variant">
                              A critical new update (v{draftConfig.latestVersionName || '1.0.0'}) is required to continue using Campusly.
                            </p>
                            {draftConfig.releaseNotes && (
                              <div className="p-3 bg-slate-50 rounded-lg text-[10px] text-slate-500 max-h-24 overflow-y-auto">
                                <strong>What's new:</strong><br />{draftConfig.releaseNotes}
                              </div>
                            )}
                            <button className="w-full py-3 bg-error text-white text-[12px] font-bold rounded-lg">Update Now</button>
                          </div>
                        </div>
                      )}

                      {/* Flexible SnackBar Alert (if flexible update is toggled) */}
                      {!draftConfig.critical && (
                        <div className="mt-auto mb-4 bg-slate-800 text-white p-3 rounded-lg flex items-center justify-between text-[11px] shadow-lg">
                          <div className="flex items-center gap-2">
                            <span className="material-symbols-outlined text-[16px] text-amber-400" style={{ fontVariationSettings: "'FILL' 1" }}>system_update</span>
                            <span>v{draftConfig.latestVersionName || '1.0.0'} available</span>
                          </div>
                          <span className="font-bold text-amber-400 cursor-pointer">DOWNLOAD</span>
                        </div>
                      )}

                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ==================== NOTICE BOARD TAB ==================== */}
          {activeTab === 'notices' && (
            <div className="space-y-6">
              <div className="mb-4">
                <p className="text-on-surface-variant font-body-lg text-body-lg">Broadcast notices and announcements directly to student mobile dashboards.</p>
              </div>

              <div className="grid grid-cols-12 gap-8">
                {/* Form */}
                <div className="col-span-12 lg:col-span-7 bg-white border border-outline-variant rounded-xl p-8 shadow-sm space-y-6">
                  <h4 className="font-title-lg text-title-lg text-on-surface font-bold">Create New Notice</h4>
                  
                  <form onSubmit={handlePostNotice} className="space-y-4">
                    <div className="space-y-1">
                      <label className="font-label-md text-label-md text-on-surface-variant block font-bold">Notice Title</label>
                      <input 
                        type="text"
                        value={newNotice.title}
                        onChange={(e) => setNewNotice({ ...newNotice, title: e.target.value })}
                        className="w-full bg-white border border-outline-variant rounded-lg px-4 py-2.5 focus:ring-2 focus:ring-secondary focus:border-secondary outline-none text-on-surface"
                        placeholder="e.g. FLAT Class Swapping"
                        required
                      />
                    </div>

                    <div className="space-y-1">
                      <label className="font-label-md text-label-md text-on-surface-variant block font-bold">Message Details</label>
                      <textarea 
                        value={newNotice.message}
                        onChange={(e) => setNewNotice({ ...newNotice, message: e.target.value })}
                        className="w-full bg-white border border-outline-variant rounded-lg px-4 py-2.5 focus:ring-2 focus:ring-secondary focus:border-secondary outline-none text-on-surface resize-none"
                        rows={5}
                        placeholder="Type notice description here..."
                        required
                      />
                    </div>

                    <div className="flex items-center justify-between p-4 bg-surface-container-low rounded-lg border border-outline-variant">
                      <div className="flex items-center gap-3">
                        <span className="material-symbols-outlined text-error" style={{ fontVariationSettings: "'FILL' 1" }}>priority_high</span>
                        <div>
                          <p className="font-body-md font-semibold text-on-surface">Mark as High Priority</p>
                          <p className="text-[11px] text-on-surface-variant">Highlights the notice card on mobile dashboards</p>
                        </div>
                      </div>
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input 
                          type="checkbox" 
                          checked={newNotice.highPriority}
                          onChange={(e) => setNewNotice({ ...newNotice, highPriority: e.target.checked })}
                          className="sr-only peer"
                        />
                        <div className="w-11 h-6 bg-outline-variant peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-secondary"></div>
                      </label>
                    </div>

                    <button 
                      type="submit" 
                      className="w-full bg-primary text-on-primary font-bold py-3.5 rounded-lg hover:bg-secondary active:scale-95 transition-all flex items-center justify-center gap-2 cursor-pointer"
                    >
                      <span className="material-symbols-outlined">send</span>
                      Publish Notice
                    </button>
                  </form>
                </div>

                {/* Mobile Preview */}
                <div className="col-span-12 lg:col-span-5 flex flex-col items-center">
                  <p className="text-label-md font-label-md text-on-surface-variant mb-4 self-start">Live Mobile Preview</p>
                  
                  {/* Phone Device Shell */}
                  <div className="relative w-[300px] h-[600px] bg-slate-900 rounded-[3rem] border-[8px] border-slate-800 shadow-2xl overflow-hidden">
                    <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-6 bg-slate-800 rounded-b-2xl z-20"></div>
                    <div className="absolute inset-0 bg-white overflow-hidden flex flex-col pt-6">
                      {/* Header */}
                      <div className="h-16 bg-white border-b border-gray-100 flex items-center px-4 pt-4">
                        <span className="material-symbols-outlined text-[18px] text-gray-500">arrow_back</span>
                        <span className="ml-2 font-bold text-[14px] text-slate-800">Notice Board</span>
                      </div>
                      
                      {/* Body List */}
                      <div className="p-4 space-y-4 flex-1 overflow-y-auto">
                        <div className="p-4 bg-slate-50 border border-slate-100 rounded-xl relative">
                          <span className={`absolute top-2 right-2 px-1.5 py-0.5 rounded text-[8px] font-bold ${
                            newNotice.highPriority ? 'bg-red-100 text-red-800' : 'bg-blue-100 text-blue-800'
                          }`}>
                            {newNotice.highPriority ? 'Alert' : 'Info'}
                          </span>
                          <h5 className="font-bold text-[13px] text-slate-800 max-w-[160px] truncate">{newNotice.title || 'Demo Notice Title'}</h5>
                          <p className="text-[10px] text-slate-400 mt-1 line-clamp-3">
                            {newNotice.message || 'Announcement details will show here. Toggling high-priority highlights this container.'}
                          </p>
                          <p className="text-[8px] text-slate-400 mt-3">Author: System Admin</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* History Notice List */}
              <div className="bg-white border border-outline-variant rounded-xl p-6 shadow-sm">
                <h4 className="font-title-lg text-title-lg font-bold text-on-surface mb-4">Notice Board History ({notices.length})</h4>
                <div className="space-y-4">
                  {notices.map(n => (
                    <div key={n.id} className="p-4 bg-surface-container-low/40 border border-outline-variant rounded-xl flex justify-between items-start gap-4">
                      <div>
                        <div className="flex items-center gap-3">
                          <h5 className="font-bold text-body-md text-on-surface">{n.title}</h5>
                          <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                            n.highPriority ? 'bg-red-100 text-red-800' : 'bg-blue-100 text-blue-800'
                          }`}>
                            {n.highPriority ? 'High Priority' : 'General'}
                          </span>
                        </div>
                        <p className="text-[13px] text-on-surface-variant mt-2">{n.message}</p>
                        <p className="text-[11px] text-outline mt-3">
                          Published: {n.timestamp?.seconds ? new Date(n.timestamp.seconds * 1000).toLocaleString() : 'Just now'}
                        </p>
                      </div>
                      <button 
                        onClick={() => handleDeleteNotice(n.id)}
                        className="p-1.5 text-on-surface-variant hover:text-error hover:bg-error-container/20 rounded-lg transition-colors cursor-pointer flex-shrink-0"
                      >
                        <span className="material-symbols-outlined text-[20px]">delete</span>
                      </button>
                    </div>
                  ))}
                  {notices.length === 0 && (
                    <p className="text-on-surface-variant text-center py-6 text-body-md">No announcements published yet.</p>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* ==================== FACULTY TAB ==================== */}
          {activeTab === 'faculty' && (
            <div className="space-y-6">
              <div className="mb-4">
                <p className="text-on-surface-variant font-body-lg text-body-lg">Manage faculty details, department listings, and office cabin coordinates.</p>
              </div>

              {/* Add Faculty Form */}
              <form onSubmit={handleAddFaculty} className="bg-white border border-outline-variant rounded-xl p-6 shadow-sm space-y-4">
                <h4 className="font-title-lg text-title-lg font-bold text-on-surface">Add Faculty Member</h4>
                
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  <div className="space-y-1">
                    <label className="font-label-md text-label-md text-on-surface-variant block font-bold">Professor Name</label>
                    <input 
                      type="text"
                      value={newFaculty.name}
                      onChange={(e) => setNewFaculty({ ...newFaculty, name: e.target.value })}
                      className="w-full bg-white border border-outline-variant rounded-lg px-3 py-2 text-body-md focus:ring-2 focus:ring-secondary focus:border-secondary outline-none text-on-surface"
                      placeholder="e.g. Dr. Priya Sharma"
                      required
                    />
                  </div>

                  <div className="space-y-1">
                    <label className="font-label-md text-label-md text-on-surface-variant block font-bold">Email Address</label>
                    <input 
                      type="email"
                      value={newFaculty.email}
                      onChange={(e) => setNewFaculty({ ...newFaculty, email: e.target.value })}
                      className="w-full bg-white border border-outline-variant rounded-lg px-3 py-2 text-body-md focus:ring-2 focus:ring-secondary focus:border-secondary outline-none text-on-surface"
                      placeholder="e.g. priya@college.edu"
                    />
                  </div>

                  <div className="space-y-1">
                    <label className="font-label-md text-label-md text-on-surface-variant block font-bold">Cabin Location</label>
                    <input 
                      type="text"
                      value={newFaculty.cabin}
                      onChange={(e) => setNewFaculty({ ...newFaculty, cabin: e.target.value })}
                      className="w-full bg-white border border-outline-variant rounded-lg px-3 py-2 text-body-md focus:ring-2 focus:ring-secondary focus:border-secondary outline-none text-on-surface"
                      placeholder="e.g. CS Block Room 402"
                      required
                    />
                  </div>

                  <div className="space-y-1">
                    <label className="font-label-md text-label-md text-on-surface-variant block font-bold">Department</label>
                    <select
                      value={newFaculty.department}
                      onChange={(e) => setNewFaculty({ ...newFaculty, department: e.target.value })}
                      className="w-full bg-white border border-outline-variant rounded-lg px-3 py-2 text-body-md focus:ring-2 focus:ring-secondary focus:border-secondary outline-none text-on-surface"
                    >
                      <option value="Computer Science">Computer Science</option>
                      <option value="Mechanical Engineering">Mechanical Engineering</option>
                      <option value="Business Management">Business Management</option>
                      <option value="Arts & Literature">Arts & Literature</option>
                    </select>
                  </div>
                </div>

                <button 
                  type="submit" 
                  className="bg-primary text-on-primary font-bold px-6 py-2.5 rounded-lg hover:bg-secondary active:scale-95 transition-all flex items-center gap-2 cursor-pointer ml-auto"
                >
                  <span className="material-symbols-outlined text-[20px]">add</span>
                  Add Faculty
                </button>
              </form>

              {/* Faculty List Table */}
              <div className="bg-white border border-outline-variant rounded-xl overflow-hidden shadow-sm">
                {/* Search & Filter Header */}
                <div className="px-6 py-4 border-b border-outline-variant bg-surface flex flex-wrap gap-4 items-center justify-between">
                  <div className="flex items-center gap-4 flex-1">
                    <div className="relative max-w-sm w-full">
                      <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-[20px]">search</span>
                      <input 
                        type="text"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full pl-10 pr-4 py-2 border border-outline-variant rounded-lg focus:ring-2 focus:ring-secondary focus:border-secondary text-body-md text-on-surface"
                        placeholder="Search by name, email, or room..."
                      />
                    </div>
                    
                    <select 
                      value={selectedDept}
                      onChange={(e) => setSelectedDept(e.target.value)}
                      className="border border-outline-variant rounded-lg px-4 py-2 text-body-md focus:ring-2 focus:ring-secondary focus:border-secondary bg-white outline-none"
                    >
                      <option value="All Departments">All Departments</option>
                      <option value="Computer Science">Computer Science</option>
                      <option value="Mechanical Engineering">Mechanical Engineering</option>
                      <option value="Business Management">Business Management</option>
                      <option value="Arts & Literature">Arts & Literature</option>
                    </select>
                  </div>
                </div>

                {/* Table */}
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse">
                    <thead className="bg-surface-container-low text-on-surface-variant font-label-sm text-label-sm uppercase tracking-wider">
                      <tr>
                        <th className="px-6 py-4 font-semibold border-b border-outline-variant">Faculty</th>
                        <th className="px-6 py-4 font-semibold border-b border-outline-variant">Email</th>
                        <th className="px-6 py-4 font-semibold border-b border-outline-variant">Department</th>
                        <th className="px-6 py-4 font-semibold border-b border-outline-variant">Cabin Location</th>
                        <th className="px-6 py-4 font-semibold border-b border-outline-variant text-right">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-outline-variant">
                      {filteredFaculties.map((f) => (
                        <tr key={f.id} className="hover:bg-surface-bright transition-colors">
                          <td className="px-6 py-4">
                            <div className="flex items-center gap-3">
                              <div className="w-10 h-10 rounded-full border border-outline-variant bg-slate-100 flex items-center justify-center text-slate-500 font-bold uppercase">
                                {f.name[0] || 'P'}
                              </div>
                              <div>
                                <p className="font-body-md font-semibold text-on-surface leading-tight">{f.name}</p>
                                <p className="text-label-md text-on-surface-variant">{f.role || 'Senior Professor'}</p>
                              </div>
                            </div>
                          </td>
                          <td className="px-6 py-4 font-body-md text-on-surface-variant">{f.email}</td>
                          <td className="px-6 py-4 font-body-md text-on-surface">{f.department}</td>
                          <td className="px-6 py-4 font-body-md text-on-surface-variant font-bold text-secondary">{f.cabin}</td>
                          <td className="px-6 py-4 text-right">
                            <button 
                              onClick={() => handleDeleteFaculty(f.id)}
                              className="p-1.5 text-on-surface-variant hover:text-error hover:bg-error-container/20 rounded-lg transition-colors cursor-pointer"
                            >
                              <span className="material-symbols-outlined text-[18px]">delete</span>
                            </button>
                          </td>
                        </tr>
                      ))}
                      {filteredFaculties.length === 0 && (
                        <tr>
                          <td colSpan={5} className="px-6 py-12 text-center text-on-surface-variant text-body-md">
                            No faculty members found matching filters.
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          </div>
        </div>
      </main>

      {/* Dynamic Module Dialog Modal */}
      {activeModal && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-fade-in">
          <div className="bg-white border border-outline-variant rounded-2xl p-8 max-w-md w-full shadow-2xl space-y-6 animate-scale-up">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-secondary-container/10 text-secondary flex items-center justify-center border border-secondary/20">
                <span className="material-symbols-outlined text-[28px]">verified_user</span>
              </div>
              <div>
                <h4 className="font-title-lg text-title-lg font-bold text-on-surface">{activeModal} Console</h4>
                <p className="text-[11px] text-emerald-800 bg-emerald-100 px-2 py-0.5 rounded font-bold uppercase tracking-wider inline-block mt-1">Live Sync Enabled</p>
              </div>
            </div>
            
            <p className="text-body-md text-on-surface-variant leading-relaxed">
              {activeModal === 'Overview' ? (
                <span>
                  Campusly workspace status overview details:<br/><br/>
                  • <strong>Total Students:</strong> {stats.usersCount}<br/>
                  • <strong>Active Notices:</strong> {stats.noticesCount}<br/>
                  • <strong>Faculty Directory Size:</strong> {stats.facultyCount}<br/>
                  • <strong>Live App Version:</strong> v{updatesConfig.latestVersionName}
                </span>
              ) : (
                <span>
                  The <strong>{activeModal}</strong> administration interface is connected and running in active standby mode. Real-time Firebase listeners are listening for schema updates.
                </span>
              )}
            </p>

            <button 
              onClick={() => setActiveModal(null)}
              className="w-full py-3 bg-primary text-on-primary font-bold rounded-xl hover:bg-secondary active:scale-95 transition-all cursor-pointer font-semibold"
            >
              Done & Close
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
