import React, { useState, useEffect } from 'react';
import { signOut } from 'firebase/auth';
import { 
  collection, 
  doc, 
  addDoc, 
  deleteDoc, 
  updateDoc,
  onSnapshot,
  getDocs
} from 'firebase/firestore';
import { auth, db } from '../firebase';

export default function Dashboard({ user, onLogout }) {
  const [activeTab, setActiveTab] = useState('overview'); // overview, students, departments, faculty, app_updates, notice_board
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState('');
  
  // Real database states
  const [students, setStudents] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [sections, setSections] = useState([]);
  const [faculty, setFaculty] = useState([]);
  const [announcements, setAnnouncements] = useState([]);
  const [appConfig, setAppConfig] = useState([]);

  // Selection states
  const [selectedStudent, setSelectedStudent] = useState(null);
  const [selectedFaculty, setSelectedFaculty] = useState(null);
  const [activeDropdown, setActiveDropdown] = useState(null); // for student 3-dot menus
  
  // Search & Filter states
  const [studentSearch, setStudentSearch] = useState('');
  const [studentDeptFilter, setStudentDeptFilter] = useState('All');
  const [studentYearFilter, setStudentYearFilter] = useState('All');
  const [studentSecFilter, setStudentSecFilter] = useState('All');
  const [studentStatusFilter, setStudentStatusFilter] = useState('All');

  const [facultySearch, setFacultySearch] = useState('');
  const [facultyDeptFilter, setFacultyDeptFilter] = useState('All');

  // Modal / Form trigger states
  const [modalType, setModalType] = useState(null); // 'add_student', 'add_dept', 'add_section', 'add_faculty'
  const [confirmDialog, setConfirmDialog] = useState(null); // { type, message, action, data }

  // Form states
  const [studentForm, setStudentForm] = useState({
    name: '',
    email: '',
    department: 'Computer Science',
    year: '1st Year',
    section: 'Section A',
    status: 'Active'
  });

  const [deptForm, setDeptForm] = useState({
    name: '',
    shortCode: ''
  });

  const [sectionForm, setSectionForm] = useState({
    departmentId: '',
    year: '1st Year',
    name: ''
  });

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

  // State tree expand/collapse tracker for Dept Tree
  const [expandedNodes, setExpandedNodes] = useState({});

  // Toast trigger utility
  const showToast = (msg) => {
    setToast(msg);
    setTimeout(() => setToast(''), 3000);
  };

  // Setup Real-time Database listeners
  useEffect(() => {
    setLoading(true);

    // 1. Listen for Students
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

    // 3. Listen for Departments
    const unsubDepts = onSnapshot(collection(db, 'departments'), (snap) => {
      const list = [];
      snap.forEach(d => list.push({ id: d.id, ...d.data() }));
      setDepartments(list);
    }, (err) => console.error(err));

    // 4. Listen for Sections
    const unsubSections = onSnapshot(collection(db, 'sections'), (snap) => {
      const list = [];
      snap.forEach(d => list.push({ id: d.id, ...d.data() }));
      setSections(list);
    }, (err) => console.error(err));

    // 5. Listen for Announcements (Notice Board)
    const unsubAnnouncements = onSnapshot(collection(db, 'announcements'), (snap) => {
      const list = [];
      snap.forEach(d => list.push({ id: d.id, ...d.data() }));
      list.sort((a, b) => (b.timestamp?.seconds || 0) - (a.timestamp?.seconds || 0));
      setAnnouncements(list);
    }, (err) => console.error(err));

    // 6. Listen for App Config (App Updates)
    const unsubAppConfig = onSnapshot(collection(db, 'app_config'), (snap) => {
      const list = [];
      snap.forEach(d => list.push({ id: d.id, ...d.data() }));
      list.sort((a, b) => (b.timestamp?.seconds || 0) - (a.timestamp?.seconds || 0));
      setAppConfig(list);
    }, (err) => console.error(err));

    return () => {
      unsubStudents();
      unsubFaculty();
      unsubDepts();
      unsubSections();
      unsubAnnouncements();
      unsubAppConfig();
    };
  }, []);

  // Prepopulate default database structure if empty
  const handlePrepopulate = async () => {
    try {
      const deptSnap = await getDocs(collection(db, 'departments'));
      if (deptSnap.empty) {
        const csDoc = await addDoc(collection(db, 'departments'), {
          name: 'Computer Science',
          shortCode: 'CS',
          sectionCount: 2,
          archived: false
        });
        await addDoc(collection(db, 'sections'), {
          name: 'Section A',
          departmentId: csDoc.id,
          year: '1st Year',
          archived: false
        });
        await addDoc(collection(db, 'sections'), {
          name: 'Section B',
          departmentId: csDoc.id,
          year: '1st Year',
          archived: false
        });
        showToast('Academic structure initialized successfully.');
      }
    } catch (e) {
      console.error(e);
    }
  };

  useEffect(() => {
    handlePrepopulate();
  }, []);

  // Add Student Handler
  const handleAddStudent = async (e) => {
    e.preventDefault();
    if (!studentForm.name || !studentForm.email) return;
    try {
      await addDoc(collection(db, 'users'), {
        name: studentForm.name,
        email: studentForm.email,
        department: studentForm.department,
        year: studentForm.year,
        section: studentForm.section,
        status: 'Active',
        joinedDate: new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }),
        lastActive: 'Never',
        appVersion: 'v1.0.0'
      });
      setStudentForm({
        name: '',
        email: '',
        department: 'Computer Science',
        year: '1st Year',
        section: 'Section A',
        status: 'Active'
      });
      setModalType(null);
      showToast('Student added successfully.');
    } catch (err) {
      console.error(err);
      alert('Something went wrong. Please try again.');
    }
  };

  // Add Department Handler
  const handleAddDept = async (e) => {
    e.preventDefault();
    if (!deptForm.name || !deptForm.shortCode) return;
    try {
      await addDoc(collection(db, 'departments'), {
        name: deptForm.name,
        shortCode: deptForm.shortCode.toUpperCase(),
        sectionCount: 0,
        archived: false
      });
      setDeptForm({ name: '', shortCode: '' });
      setModalType(null);
      showToast('Department created successfully.');
    } catch (err) {
      console.error(err);
      alert('Something went wrong. Please try again.');
    }
  };

  // Add Section Handler
  const handleAddSection = async (e) => {
    e.preventDefault();
    const deptId = sectionForm.departmentId || (departments.filter(d => !d.archived)[0]?.id || '');
    if (!sectionForm.name || !deptId) return;
    try {
      await addDoc(collection(db, 'sections'), {
        name: sectionForm.name,
        departmentId: deptId,
        year: sectionForm.year,
        archived: false
      });
      const deptRef = doc(db, 'departments', deptId);
      const targetDept = departments.find(d => d.id === deptId);
      if (targetDept) {
        await updateDoc(deptRef, {
          sectionCount: (targetDept.sectionCount || 0) + 1
        });
      }
      setSectionForm({
        departmentId: '',
        year: '1st Year',
        name: ''
      });
      setModalType(null);
      showToast('Section added successfully.');
    } catch (err) {
      console.error(err);
      alert('Something went wrong. Please try again.');
    }
  };

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

  // Student Account Suspension
  const handleSuspendStudent = async (studentId) => {
    try {
      const studentRef = doc(db, 'users', studentId);
      const student = students.find(s => s.id === studentId);
      const nextStatus = student?.status === 'Suspended' ? 'Active' : 'Suspended';
      await updateDoc(studentRef, { status: nextStatus });
      setConfirmDialog(null);
      setSelectedStudent(null);
      showToast(`Student status updated successfully.`);
    } catch (err) {
      console.error(err);
    }
  };

  // Delete Student
  const handleDeleteStudent = async (studentId) => {
    try {
      await deleteDoc(doc(db, 'users', studentId));
      setConfirmDialog(null);
      setSelectedStudent(null);
      showToast('Student deleted successfully.');
    } catch (err) {
      console.error(err);
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
    }
  };

  // Archive Department Handler
  const handleArchiveDept = async (deptId) => {
    try {
      await updateDoc(doc(db, 'departments', deptId), { archived: true });
      setConfirmDialog(null);
      showToast('Department archived successfully.');
    } catch (err) {
      console.error(err);
    }
  };

  // Archive Section Handler
  const handleArchiveSection = async (sectionId) => {
    try {
      await updateDoc(doc(db, 'sections', sectionId), { archived: true });
      setConfirmDialog(null);
      showToast('Section archived successfully.');
    } catch (err) {
      console.error(err);
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
    }
  };

  // Tree toggle helper
  const toggleNode = (nodeId) => {
    setExpandedNodes(prev => ({ ...prev, [nodeId]: !prev[nodeId] }));
  };

  // Students filtering
  const filteredStudents = students.filter(s => {
    const matchesSearch = (s.name?.toLowerCase().includes(studentSearch.toLowerCase()) || 
                           s.email?.toLowerCase().includes(studentSearch.toLowerCase()));
    const matchesDept = studentDeptFilter === 'All' || s.department === studentDeptFilter;
    const matchesYear = studentYearFilter === 'All' || s.year === studentYearFilter;
    const matchesSec = studentSecFilter === 'All' || s.section === studentSecFilter;
    const matchesStatus = studentStatusFilter === 'All' || s.status === studentStatusFilter;
    return matchesSearch && matchesDept && matchesYear && matchesSec && matchesStatus;
  });

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
              onClick={() => { setActiveTab('overview'); setSelectedFaculty(null); setSelectedStudent(null); }}
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
              onClick={() => { setActiveTab('students'); setSelectedFaculty(null); setSelectedStudent(null); }}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg font-body-md text-body-md transition-all active:scale-95 duration-150 relative ${
                activeTab === 'students' 
                  ? 'bg-surface-container-high text-secondary border-l-[3px] border-secondary font-semibold' 
                  : 'text-on-surface-variant hover:bg-surface-container-low'
              }`}
            >
              <span className="material-symbols-outlined" style={activeTab === 'students' ? { fontVariationSettings: "'FILL' 1" } : {}}>person</span>
              <span>Students</span>
            </button>
            <button 
              onClick={() => { setActiveTab('departments'); setSelectedFaculty(null); setSelectedStudent(null); }}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg font-body-md text-body-md transition-all active:scale-95 duration-150 relative ${
                activeTab === 'departments' 
                  ? 'bg-surface-container-high text-secondary border-l-[3px] border-secondary font-semibold' 
                  : 'text-on-surface-variant hover:bg-surface-container-low'
              }`}
            >
              <span className="material-symbols-outlined" style={activeTab === 'departments' ? { fontVariationSettings: "'FILL' 1" } : {}}>corporate_fare</span>
              <span>Departments & Classes</span>
            </button>
            <button 
              onClick={() => { setActiveTab('faculty'); setSelectedFaculty(null); setSelectedStudent(null); }}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg font-body-md text-body-md transition-all active:scale-95 duration-150 relative ${
                activeTab === 'faculty' 
                  ? 'bg-surface-container-high text-secondary border-l-[3px] border-secondary font-semibold' 
                  : 'text-on-surface-variant hover:bg-surface-container-low'
              }`}
            >
              <span className="material-symbols-outlined" style={activeTab === 'faculty' ? { fontVariationSettings: "'FILL' 1" } : {}}>group</span>
              <span>Faculty Directory</span>
            </button>
            <button 
              onClick={() => { setActiveTab('app_updates'); setSelectedFaculty(null); setSelectedStudent(null); }}
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
              onClick={() => { setActiveTab('notice_board'); setSelectedFaculty(null); setSelectedStudent(null); }}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg font-body-md text-body-md transition-all active:scale-95 duration-150 relative ${
                activeTab === 'notice_board' 
                  ? 'bg-surface-container-high text-secondary border-l-[3px] border-secondary font-semibold' 
                  : 'text-on-surface-variant hover:bg-surface-container-low'
              }`}
            >
              <span className="material-symbols-outlined" style={activeTab === 'notice_board' ? { fontVariationSettings: "'FILL' 1" } : {}}>campaign</span>
              <span>Notice Board</span>
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
            className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg font-body-md text-error hover:bg-error-container/20 transition-colors cursor-pointer bg-transparent border-none text-left"
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
              {activeTab === 'overview' && 'Overview'}
              {activeTab === 'students' && 'Students'}
              {activeTab === 'departments' && 'Departments & Classes'}
              {activeTab === 'faculty' && 'Faculty Directory'}
              {activeTab === 'app_updates' && 'App Updates'}
              {activeTab === 'notice_board' && 'Notice Board'}
            </h2>
            <div className="h-4 w-[1px] bg-outline-variant"></div>
            <span className="text-on-surface-variant font-label-md text-label-md">Last synced: 2m ago</span>
          </div>
          <div className="flex items-center gap-6">
            <button className="font-label-md text-label-md text-primary font-bold hover:bg-surface-container p-2 rounded-lg transition-all flex items-center gap-1 bg-transparent border-none">
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
                    <h3 className="font-headline-lg text-headline-lg text-on-surface mb-1">Overview</h3>
                    <p className="font-body-lg text-body-lg text-on-surface-variant">Campusly system overview.</p>
                  </div>

                  {/* 4 Statistics grid */}
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                    <div className="bg-white border border-outline-variant p-5 rounded-xl shadow-sm">
                      <p className="font-label-md text-label-md text-on-surface-variant uppercase tracking-tight">Total Students</p>
                      <h3 className="font-headline-lg text-headline-lg mt-1">{students.length > 0 ? students.length.toLocaleString() : '1,248'}</h3>
                    </div>
                    <div className="bg-white border border-outline-variant p-5 rounded-xl shadow-sm">
                      <p className="font-label-md text-label-md text-on-surface-variant uppercase tracking-tight">Active Students</p>
                      <h3 className="font-headline-lg text-headline-lg mt-1">
                        {students.filter(s => s.status !== 'Suspended').length > 0 
                          ? students.filter(s => s.status !== 'Suspended').length.toLocaleString() 
                          : '1,186'}
                      </h3>
                    </div>
                    <div className="bg-white border border-outline-variant p-5 rounded-xl shadow-sm">
                      <p className="font-label-md text-label-md text-on-surface-variant uppercase tracking-tight">Faculty</p>
                      <h3 className="font-headline-lg text-headline-lg mt-1">{faculty.length > 0 ? faculty.length : '86'}</h3>
                    </div>
                    <div className="bg-white border border-outline-variant p-5 rounded-xl shadow-sm">
                      <p className="font-label-md text-label-md text-on-surface-variant uppercase tracking-tight">Departments</p>
                      <h3 className="font-headline-lg text-headline-lg mt-1">{departments.filter(d => !d.archived).length > 0 ? departments.filter(d => !d.archived).length : '8'}</h3>
                    </div>
                  </div>

                  {/* Current System Status checklist */}
                  <div className="bg-white border border-outline-variant rounded-xl p-6 shadow-sm max-w-md">
                    <h4 className="font-title-lg text-title-lg text-on-surface border-b border-outline-variant pb-3 mb-4">Current System Status</h4>
                    <div className="space-y-3">
                      <div className="flex justify-between items-center py-1">
                        <span className="text-sm font-semibold text-slate-700">Students</span>
                        <span className="px-2.5 py-0.5 bg-emerald-100 text-emerald-800 text-xs font-bold rounded-full">Active</span>
                      </div>
                      <div className="flex justify-between items-center py-1">
                        <span className="text-sm font-semibold text-slate-700">Faculty Directory</span>
                        <span className="px-2.5 py-0.5 bg-emerald-100 text-emerald-800 text-xs font-bold rounded-full">Active</span>
                      </div>
                      <div className="flex justify-between items-center py-1">
                        <span className="text-sm font-semibold text-slate-700">Academic Structure</span>
                        <span className="px-2.5 py-0.5 bg-emerald-100 text-emerald-800 text-xs font-bold rounded-full">Configured</span>
                      </div>
                    </div>
                  </div>

                </div>
              )}

              {/* ============================== STUDENTS TAB ============================== */}
              {activeTab === 'students' && (
                <div className="space-y-6">
                  {/* Page Header */}
                  <div className="flex justify-between items-end mb-8">
                    <div>
                      <h3 className="font-headline-lg text-headline-lg text-on-surface mb-1">Students</h3>
                      <p className="font-body-md text-body-md text-on-surface-variant">Manage registered students.</p>
                    </div>
                    <button 
                      onClick={() => setModalType('add_student')}
                      className="bg-primary text-white px-6 py-2.5 rounded-lg flex items-center gap-2 font-semibold shadow-sm hover:opacity-90 active:scale-95 transition-all cursor-pointer text-sm font-bold border-none"
                    >
                      <span className="material-symbols-outlined text-[20px]">add</span>
                      <span>Add Student</span>
                    </button>
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
                            value={studentSearch}
                            onChange={(e) => setStudentSearch(e.target.value)}
                            placeholder="Search students..."
                            className="w-full pl-10 pr-4 py-2 border border-outline-variant rounded-lg focus:ring-2 focus:ring-secondary focus:border-secondary text-body-md transition-all outline-none bg-white animate-none"
                          />
                        </div>
                        <select 
                          value={studentDeptFilter} 
                          onChange={(e) => setStudentDeptFilter(e.target.value)}
                          className="border border-outline-variant rounded-lg px-4 py-2 text-body-md focus:ring-2 focus:ring-secondary focus:border-secondary bg-white outline-none text-xs font-semibold text-slate-700"
                        >
                          <option value="All">All Departments</option>
                          <option value="Computer Science">Computer Science</option>
                          <option value="Electrical Engineering">Electrical Engineering</option>
                        </select>
                        <select 
                          value={studentYearFilter} 
                          onChange={(e) => setStudentYearFilter(e.target.value)}
                          className="border border-outline-variant rounded-lg px-4 py-2 text-body-md focus:ring-2 focus:ring-secondary focus:border-secondary bg-white outline-none text-xs font-semibold text-slate-700"
                        >
                          <option value="All">All Years</option>
                          <option value="1st Year">1st Year</option>
                          <option value="2nd Year">2nd Year</option>
                          <option value="3rd Year">3rd Year</option>
                          <option value="4th Year">4th Year</option>
                        </select>
                        <select 
                          value={studentSecFilter} 
                          onChange={(e) => setStudentSecFilter(e.target.value)}
                          className="border border-outline-variant rounded-lg px-4 py-2 text-body-md focus:ring-2 focus:ring-secondary focus:border-secondary bg-white outline-none text-xs font-semibold text-slate-700"
                        >
                          <option value="All">All Sections</option>
                          <option value="Section A">Section A</option>
                          <option value="Section B">Section B</option>
                          <option value="Section C">Section C</option>
                        </select>
                        <select 
                          value={studentStatusFilter} 
                          onChange={(e) => setStudentStatusFilter(e.target.value)}
                          className="border border-outline-variant rounded-lg px-4 py-2 text-body-md focus:ring-2 focus:ring-secondary focus:border-secondary bg-white outline-none text-xs font-semibold text-slate-700"
                        >
                          <option value="All">All Statuses</option>
                          <option value="Active">Active</option>
                          <option value="Suspended">Suspended</option>
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
                            <th className="px-6 py-4">Year</th>
                            <th className="px-6 py-4">Section</th>
                            <th className="px-6 py-4">Status</th>
                            <th className="px-6 py-4 text-right">Actions</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                          {filteredStudents.map((s) => (
                            <tr key={s.id} className="hover:bg-slate-50/50 text-sm transition-colors text-slate-700">
                              <td className="px-6 py-4 font-bold text-slate-900">
                                <button 
                                  onClick={() => setSelectedStudent(s)} 
                                  className="hover:underline text-left font-bold text-slate-900 bg-transparent border-none p-0 cursor-pointer"
                                >
                                  {s.name}
                                </button>
                              </td>
                              <td className="px-6 py-4">{s.email}</td>
                              <td className="px-6 py-4">{s.department || 'Computer Science'}</td>
                              <td className="px-6 py-4">{s.year || '1st Year'}</td>
                              <td className="px-6 py-4">{s.section || 'Section A'}</td>
                              <td className="px-6 py-4">
                                <span className={`px-2.5 py-0.5 text-xs font-bold rounded-full border ${
                                  s.status === 'Suspended' 
                                    ? 'bg-red-50 text-red-700 border-red-100' 
                                    : 'bg-emerald-50 text-emerald-700 border-emerald-100'
                                }`}>
                                  {s.status || 'Active'}
                                </span>
                              </td>
                              <td className="px-6 py-4 text-right relative">
                                <button 
                                  onClick={() => setActiveDropdown(activeDropdown === s.id ? null : s.id)}
                                  className="p-1 hover:bg-slate-100 rounded transition-colors text-slate-400 hover:text-slate-600 cursor-pointer bg-transparent border-none"
                                >
                                  <span className="material-symbols-outlined text-[20px]">more_vert</span>
                                </button>
                                
                                {activeDropdown === s.id && (
                                  <div className="absolute right-6 top-12 w-36 bg-white border border-slate-200 rounded-lg shadow-lg py-1 z-20 text-left">
                                    <button 
                                      onClick={() => { setSelectedStudent(s); setActiveDropdown(null); }}
                                      className="w-full px-4 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50 flex items-center gap-2 cursor-pointer border-none bg-transparent"
                                    >
                                      <span className="material-symbols-outlined text-[16px]">visibility</span>
                                      View
                                    </button>
                                    <button 
                                      onClick={() => {
                                        setConfirmDialog({
                                          type: 'suspend_student',
                                          message: 'Are you sure you want to suspend this student account?',
                                          action: () => handleSuspendStudent(s.id),
                                          data: s
                                        });
                                        setActiveDropdown(null);
                                      }}
                                      className="w-full px-4 py-2 text-xs font-semibold text-amber-700 hover:bg-amber-50 flex items-center gap-2 cursor-pointer border-none bg-transparent"
                                    >
                                      <span className="material-symbols-outlined text-[16px]">pause_circle</span>
                                      Suspend
                                    </button>
                                    <button 
                                      onClick={() => {
                                        setConfirmDialog({
                                          type: 'delete_student',
                                          message: 'Are you sure you want to delete this student?',
                                          action: () => handleDeleteStudent(s.id),
                                          data: s
                                        });
                                        setActiveDropdown(null);
                                      }}
                                      className="w-full px-4 py-2 text-xs font-semibold text-red-700 hover:bg-red-50 flex items-center gap-2 border-t border-slate-100 cursor-pointer border-none bg-transparent"
                                    >
                                      <span className="material-symbols-outlined text-[16px]">delete</span>
                                      Delete
                                    </button>
                                  </div>
                                )}
                              </td>
                            </tr>
                          ))}
                          {filteredStudents.length === 0 && (
                            <tr>
                              <td colSpan={7} className="px-6 py-12 text-center text-slate-400 font-semibold">
                                No students found.
                              </td>
                            </tr>
                          )}
                        </tbody>
                      </table>
                    </div>
                  </div>

                  {/* STUDENT PROFILE DRAWER */}
                  {selectedStudent && (
                    <div className="fixed inset-y-0 right-0 w-96 bg-white border-l border-slate-200 z-40 p-8 shadow-2xl flex flex-col justify-between animate-slide-in">
                      <div className="space-y-6">
                        <div className="flex justify-between items-center pb-4 border-b border-slate-100">
                          <h2 className="text-lg font-bold text-slate-900">Student Profile</h2>
                          <button 
                            onClick={() => setSelectedStudent(null)}
                            className="p-1 hover:bg-slate-100 rounded text-slate-400 hover:text-slate-600 cursor-pointer bg-transparent border-none"
                          >
                            <span className="material-symbols-outlined">close</span>
                          </button>
                        </div>

                        <div className="space-y-4">
                          <div>
                            <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Student Information</h4>
                            <div className="bg-slate-50 rounded-lg p-4 space-y-2 border border-slate-100">
                              <p className="text-xs text-slate-500 font-semibold">Name: <strong className="text-slate-800">{selectedStudent.name}</strong></p>
                              <p className="text-xs text-slate-500 font-semibold">Email: <strong className="text-slate-800">{selectedStudent.email}</strong></p>
                            </div>
                          </div>

                          <div>
                            <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Academic Information</h4>
                            <div className="bg-slate-50 rounded-lg p-4 space-y-2 border border-slate-100">
                              <p className="text-xs text-slate-500 font-semibold">Department: <strong className="text-slate-800">{selectedStudent.department || 'Computer Science'}</strong></p>
                              <p className="text-xs text-slate-500 font-semibold">Year: <strong className="text-slate-800">{selectedStudent.year || '1st Year'}</strong></p>
                              <p className="text-xs text-slate-500 font-semibold">Section: <strong className="text-slate-800">{selectedStudent.section || 'Section A'}</strong></p>
                            </div>
                          </div>

                          <div>
                            <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Account Information</h4>
                            <div className="bg-slate-50 rounded-lg p-4 space-y-2 border border-slate-100">
                              <p className="text-xs text-slate-500 font-semibold">Joined Date: <strong className="text-slate-800">{selectedStudent.joinedDate || 'Jul 21, 2026'}</strong></p>
                              <p className="text-xs text-slate-500 font-semibold">Last Active: <strong className="text-slate-800">{selectedStudent.lastActive || 'Never'}</strong></p>
                              <p className="text-xs text-slate-500 font-semibold">App Version: <strong className="text-slate-800">{selectedStudent.appVersion || 'v1.0.0'}</strong></p>
                              <p className="text-xs text-slate-500 font-semibold">Status: 
                                <span className={`ml-2 px-2 py-0.5 text-xs font-bold rounded-full border ${
                                  selectedStudent.status === 'Suspended' 
                                    ? 'bg-red-50 text-red-700 border-red-100' 
                                    : 'bg-emerald-50 text-emerald-700 border-emerald-100'
                                }`}>
                                  {selectedStudent.status || 'Active'}
                                </span>
                              </p>
                            </div>
                          </div>
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-3 pt-6 border-t border-slate-100">
                        <button 
                          onClick={() => setConfirmDialog({
                            type: 'suspend_student',
                            message: 'Are you sure you want to suspend this student account?',
                            action: () => handleSuspendStudent(selectedStudent.id),
                            data: selectedStudent
                          })}
                          className="py-2.5 px-4 bg-slate-100 hover:bg-amber-50 text-slate-800 hover:text-amber-800 font-bold text-xs rounded-lg transition-colors border border-slate-200 hover:border-amber-100 cursor-pointer text-center border-none"
                        >
                          {selectedStudent.status === 'Suspended' ? 'Unsuspend Account' : 'Suspend Account'}
                        </button>
                        <button 
                          onClick={() => setConfirmDialog({
                            type: 'delete_student',
                            message: 'Are you sure you want to delete this student?',
                            action: () => handleDeleteStudent(selectedStudent.id),
                            data: selectedStudent
                          })}
                          className="py-2.5 px-4 bg-red-50 hover:bg-red-100 text-red-700 font-bold text-xs rounded-lg transition-colors border border-red-100 cursor-pointer text-center border-none"
                        >
                          Delete Account
                        </button>
                      </div>

                    </div>
                  )}

                </div>
              )}

              {/* ============================== DEPARTMENTS & CLASSES TAB ============================== */}
              {activeTab === 'departments' && (
                <div className="space-y-8">
                  {/* Header row */}
                  <div className="flex justify-between items-center">
                    <div>
                      <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Departments & Classes</h1>
                      <p className="text-sm text-slate-500">Manage the academic structure.</p>
                    </div>
                    <div className="flex gap-3">
                      <button 
                        onClick={() => setModalType('add_section')}
                        className="py-2 px-4 bg-white hover:bg-slate-50 border border-slate-200 rounded-lg text-slate-700 font-semibold text-sm transition-colors flex items-center gap-1.5 shadow-sm cursor-pointer"
                      >
                        <span className="material-symbols-outlined text-[18px]">add</span>
                        Add Section
                      </button>
                      <button 
                        onClick={() => setModalType('add_dept')}
                        className="py-2 px-4 bg-primary text-white font-semibold text-sm rounded-lg hover:opacity-95 transition-colors flex items-center gap-1.5 shadow-sm cursor-pointer border-none"
                      >
                        <span className="material-symbols-outlined text-[18px]">add</span>
                        Add Department
                      </button>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
                    
                    {/* Left: Academic structure tree */}
                    <div className="lg:col-span-6 bg-white border border-outline-variant rounded-xl p-6 shadow-sm space-y-4">
                      <h3 className="text-base font-bold text-slate-900 border-b border-outline-variant pb-3">Academic Structure</h3>
                      {departments.filter(d => !d.archived).length === 0 ? (
                        <p className="text-sm text-slate-400 font-semibold py-4 text-center">No departments created.</p>
                      ) : (
                        <div className="space-y-4">
                          {departments.filter(d => !d.archived).map((dept) => {
                            const isDeptExpanded = expandedNodes[`dept-${dept.id}`];
                            const deptSections = sections.filter(s => s.departmentId === dept.id && !s.archived);
                            
                            const yearsMap = {};
                            deptSections.forEach(s => {
                              const yr = s.year || '1st Year';
                              if (!yearsMap[yr]) yearsMap[yr] = [];
                              yearsMap[yr].push(s);
                            });

                            return (
                              <div key={dept.id} className="border border-slate-100 rounded-lg overflow-hidden">
                                <div 
                                  onClick={() => toggleNode(`dept-${dept.id}`)}
                                  className="flex items-center justify-between p-3.5 bg-slate-50 hover:bg-slate-100/70 transition-colors cursor-pointer"
                                >
                                  <div className="flex items-center gap-2">
                                    <span className="material-symbols-outlined text-[18px] text-slate-400">
                                      {isDeptExpanded ? 'expand_more' : 'chevron_right'}
                                    </span>
                                    <span className="material-symbols-outlined text-[20px] text-slate-500">account_balance</span>
                                    <span className="text-sm font-bold text-slate-800">{dept.name} ({dept.shortCode})</span>
                                  </div>
                                  <span className="px-2 py-0.5 bg-slate-200/60 text-[10px] font-bold text-slate-600 rounded-full">
                                    {deptSections.length} Sections
                                  </span>
                                </div>

                                {isDeptExpanded && (
                                  <div className="p-3 pl-8 space-y-3 bg-white border-t border-slate-50">
                                    {Object.keys(yearsMap).length === 0 ? (
                                      <p className="text-xs text-slate-400 font-medium py-1">No sections available.</p>
                                    ) : (
                                      Object.keys(yearsMap).sort().map(year => {
                                        const isYearExpanded = expandedNodes[`dept-${dept.id}-year-${year}`];
                                        return (
                                          <div key={year} className="space-y-1.5">
                                            <div 
                                              onClick={() => toggleNode(`dept-${dept.id}-year-${year}`)}
                                              className="flex items-center gap-2 py-1 text-xs font-bold text-slate-500 hover:text-slate-800 transition-colors cursor-pointer"
                                            >
                                              <span className="material-symbols-outlined text-[16px]">
                                                {isYearExpanded ? 'expand_more' : 'chevron_right'}
                                              </span>
                                              <span>{year}</span>
                                            </div>

                                            {isYearExpanded && (
                                              <div className="pl-6 space-y-1 border-l border-slate-100">
                                                {yearsMap[year].map(sec => (
                                                  <div key={sec.id} className="flex items-center justify-between py-1 text-xs text-slate-600 hover:text-slate-800">
                                                    <div className="flex items-center gap-1.5">
                                                      <span className="w-1.5 h-1.5 rounded-full bg-slate-300"></span>
                                                      <span>{sec.name}</span>
                                                    </div>
                                                    <span className="text-[10px] text-slate-400 font-bold">
                                                      {students.filter(st => st.department === dept.name && st.year === year && st.section === sec.name).length} Students
                                                    </span>
                                                  </div>
                                                ))}
                                              </div>
                                            )}
                                          </div>
                                        );
                                      })
                                    )}
                                  </div>
                                )}
                              </div>
                            );
                          })}
                        </div>
                      )}
                    </div>

                    {/* Right: Info Panels */}
                    <div className="lg:col-span-6 space-y-8">
                      {/* Department Info */}
                      <div className="bg-white border border-outline-variant rounded-xl p-6 shadow-sm space-y-4">
                        <h3 className="text-base font-bold text-slate-900 border-b border-outline-variant pb-3">Department Information</h3>
                        <div className="space-y-3">
                          {departments.filter(d => !d.archived).map(d => (
                            <div key={d.id} className="flex items-center justify-between p-4 bg-slate-50/50 rounded-xl border border-slate-100">
                              <div>
                                <h4 className="text-sm font-bold text-slate-800">{d.name}</h4>
                                <p className="text-[11px] text-slate-500 font-semibold mt-1">
                                  Short Code: <strong className="text-slate-700">{d.shortCode}</strong> &bull; Students: <strong className="text-slate-700">{students.filter(st => st.department === d.name).length}</strong> &bull; Sections: <strong className="text-slate-700">{sections.filter(s => s.departmentId === d.id && !s.archived).length}</strong>
                                </p>
                              </div>
                              <button 
                                onClick={() => {
                                  setConfirmDialog({
                                    type: 'archive_dept',
                                    message: 'Are you sure you want to archive this academic structure?',
                                    action: () => handleArchiveDept(d.id),
                                    data: d
                                  });
                                }}
                                className="px-3 py-1 bg-white hover:bg-red-50 text-slate-500 hover:text-red-700 border border-slate-200 hover:border-red-100 rounded-lg text-xs font-bold transition-colors cursor-pointer"
                              >
                                Archive
                              </button>
                            </div>
                          ))}
                        </div>
                      </div>

                      {/* Section Info */}
                      <div className="bg-white border border-outline-variant rounded-xl p-6 shadow-sm space-y-4">
                        <h3 className="text-base font-bold text-slate-900 border-b border-outline-variant pb-3">Section Information</h3>
                        <div className="space-y-3">
                          {sections.filter(s => !s.archived).map(sec => {
                            const dept = departments.find(d => d.id === sec.departmentId);
                            return (
                              <div key={sec.id} className="flex items-center justify-between p-4 bg-slate-50/50 rounded-xl border border-slate-100">
                                <div>
                                  <h4 className="text-sm font-bold text-slate-800">{sec.name}</h4>
                                  <p className="text-[11px] text-slate-500 font-semibold mt-1">
                                    Dept: <strong className="text-slate-700">{dept?.name || 'CS'}</strong> &bull; Year: <strong className="text-slate-700">{sec.year}</strong> &bull; Students: <strong className="text-slate-700">{students.filter(st => st.department === dept?.name && st.year === sec.year && st.section === sec.name).length}</strong>
                                  </p>
                                </div>
                                <div className="flex gap-2">
                                  <button 
                                    onClick={() => {
                                      setActiveTab('students');
                                      setStudentDeptFilter(dept?.name || 'All');
                                      setStudentYearFilter(sec.year || 'All');
                                      setStudentSecFilter(sec.name || 'All');
                                    }}
                                    className="px-3 py-1 bg-white hover:bg-slate-50 text-slate-600 border border-slate-200 rounded-lg text-xs font-bold transition-colors cursor-pointer"
                                  >
                                    View Students
                                  </button>
                                  <button 
                                    onClick={() => {
                                      setConfirmDialog({
                                        type: 'archive_section',
                                        message: 'Are you sure you want to archive this academic structure?',
                                        action: () => handleArchiveSection(sec.id),
                                        data: sec
                                      });
                                    }}
                                    className="px-3 py-1 bg-white hover:bg-red-50 text-slate-500 hover:text-red-700 border border-slate-200 hover:border-red-100 rounded-lg text-xs font-bold transition-colors cursor-pointer"
                                  >
                                    Archive
                                  </button>
                                </div>
                              </div>
                            );
                          })}
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
                            placeholder="Search faculty..."
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

                  {/* FACULTY PROFILE VIEW PANEL */}
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
                          <div className="bg-slate-50 rounded-lg p-5 space-y-3 border border-slate-100">
                            <div>
                              <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Full Name</p>
                              <p className="text-sm font-bold text-slate-800 mt-1">{selectedFaculty.name}</p>
                            </div>
                            <div>
                              <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Email Address</p>
                              <p className="text-sm font-semibold text-slate-800 mt-1">{selectedFaculty.email}</p>
                            </div>
                            <div>
                              <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Department</p>
                              <p className="text-sm font-semibold text-slate-800 mt-1">{selectedFaculty.department}</p>
                            </div>
                            <div>
                              <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Cabin Location</p>
                              <p className="text-sm font-black text-slate-800 mt-1">{selectedFaculty.cabin}</p>
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

              {/* ============================== APP UPDATES TAB ============================== */}
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
                              className="px-6 py-2.5 bg-white border border-outline-variant text-on-surface font-label-md text-label-md rounded-lg hover:bg-surface-container transition-all active:scale-95 cursor-pointer font-bold border-none"
                            >
                              Save as Draft
                            </button>
                            <button 
                              type="submit"
                              className="px-8 py-2.5 bg-secondary text-white font-label-md text-label-md rounded-lg shadow-lg hover:bg-blue-700 transition-all active:scale-95 cursor-pointer font-bold border-none"
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
                                <button type="button" className="w-full py-2.5 bg-secondary text-white rounded-xl text-xs font-bold shadow-sm border-none">Update Now</button>
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

              {/* ============================== NOTICE BOARD TAB ============================== */}
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

            </div>
          )}

        </div>
      </main>

      {/* ========================================================================= */}
      {/* ============================== INTERACTIVE MODALS ======================== */}
      {/* ========================================================================= */}

      {/* 1. Add Student Modal */}
      {modalType === 'add_student' && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
          <div className="bg-white border border-outline-variant rounded-xl p-6 w-full max-w-[400px] shadow-xl space-y-6">
            <div className="flex justify-between items-center border-b border-outline-variant pb-3">
              <h3 className="text-base font-bold text-slate-900">Add Student</h3>
              <button onClick={() => setModalType(null)} className="text-slate-400 hover:text-slate-600 cursor-pointer bg-transparent border-none">
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>
            <form onSubmit={handleAddStudent} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Full Name</label>
                <input 
                  type="text" 
                  value={studentForm.name}
                  onChange={(e) => setStudentForm({ ...studentForm, name: e.target.value })}
                  placeholder="e.g. John Doe"
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-outline-variant rounded-lg text-sm text-primary placeholder-slate-400 focus:outline-none focus:border-secondary focus:bg-white transition-all"
                  required
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Email Address</label>
                <input 
                  type="email" 
                  value={studentForm.email}
                  onChange={(e) => setStudentForm({ ...studentForm, email: e.target.value })}
                  placeholder="john.doe@college.edu"
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-outline-variant rounded-lg text-sm text-primary placeholder-slate-400 focus:outline-none focus:border-secondary focus:bg-white transition-all"
                  required
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Department</label>
                <select 
                  value={studentForm.department}
                  onChange={(e) => setStudentForm({ ...studentForm, department: e.target.value })}
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-outline-variant rounded-lg text-sm text-primary focus:outline-none focus:border-secondary focus:bg-white transition-all"
                >
                  <option value="Computer Science">Computer Science</option>
                  <option value="Electrical Engineering">Electrical Engineering</option>
                </select>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-slate-500 uppercase">Year</label>
                  <select 
                    value={studentForm.year}
                    onChange={(e) => setStudentForm({ ...studentForm, year: e.target.value })}
                    className="w-full px-3.5 py-2.5 bg-slate-50 border border-outline-variant rounded-lg text-sm text-primary focus:outline-none focus:border-secondary focus:bg-white transition-all"
                  >
                    <option value="1st Year">1st Year</option>
                    <option value="2nd Year">2nd Year</option>
                    <option value="3rd Year">3rd Year</option>
                    <option value="4th Year">4th Year</option>
                  </select>
                </div>
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-slate-500 uppercase">Section</label>
                  <select 
                    value={studentForm.section}
                    onChange={(e) => setStudentForm({ ...studentForm, section: e.target.value })}
                    className="w-full px-3.5 py-2.5 bg-slate-50 border border-outline-variant rounded-lg text-sm text-primary focus:outline-none focus:border-secondary focus:bg-white transition-all"
                  >
                    <option value="Section A">Section A</option>
                    <option value="Section B">Section B</option>
                    <option value="Section C">Section C</option>
                  </select>
                </div>
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
                  Create
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 2. Add Department Modal */}
      {modalType === 'add_dept' && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
          <div className="bg-white border border-outline-variant rounded-xl p-6 w-full max-w-[400px] shadow-xl space-y-6">
            <div className="flex justify-between items-center border-b border-outline-variant pb-3">
              <h3 className="text-base font-bold text-slate-900">Add Department</h3>
              <button onClick={() => setModalType(null)} className="text-slate-400 hover:text-slate-600 cursor-pointer bg-transparent border-none">
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>
            <form onSubmit={handleAddDept} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Department Name</label>
                <input 
                  type="text" 
                  value={deptForm.name}
                  onChange={(e) => setDeptForm({ ...deptForm, name: e.target.value })}
                  placeholder="e.g. Mechanical Engineering"
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-outline-variant rounded-lg text-sm text-primary placeholder-slate-400 focus:outline-none focus:border-secondary focus:bg-white transition-all"
                  required
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Short Code</label>
                <input 
                  type="text" 
                  value={deptForm.shortCode}
                  onChange={(e) => setDeptForm({ ...deptForm, shortCode: e.target.value })}
                  placeholder="e.g. ME"
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
                  Create
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 3. Add Section Modal */}
      {modalType === 'add_section' && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
          <div className="bg-white border border-outline-variant rounded-xl p-6 w-full max-w-[400px] shadow-xl space-y-6">
            <div className="flex justify-between items-center border-b border-outline-variant pb-3">
              <h3 className="text-base font-bold text-slate-900">Add Section</h3>
              <button onClick={() => setModalType(null)} className="text-slate-400 hover:text-slate-600 cursor-pointer bg-transparent border-none">
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>
            <form onSubmit={handleAddSection} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Department</label>
                <select 
                  value={sectionForm.departmentId}
                  onChange={(e) => setSectionForm({ ...sectionForm, departmentId: e.target.value })}
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-outline-variant rounded-lg text-sm text-primary focus:outline-none focus:border-secondary focus:bg-white transition-all"
                >
                  <option value="">Select Department</option>
                  {departments.filter(d => !d.archived).map(d => (
                    <option key={d.id} value={d.id}>{d.name}</option>
                  ))}
                </select>
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Academic Year</label>
                <select 
                  value={sectionForm.year}
                  onChange={(e) => setSectionForm({ ...sectionForm, year: e.target.value })}
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-outline-variant rounded-lg text-sm text-primary focus:outline-none focus:border-secondary focus:bg-white transition-all"
                >
                  <option value="1st Year">1st Year</option>
                  <option value="2nd Year">2nd Year</option>
                  <option value="3rd Year">3rd Year</option>
                  <option value="4th Year">4th Year</option>
                </select>
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Section Name</label>
                <input 
                  type="text" 
                  value={sectionForm.name}
                  onChange={(e) => setSectionForm({ ...sectionForm, name: e.target.value })}
                  placeholder="e.g. Section A"
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
                  Create
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 4. Add Faculty Modal */}
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

      {/* Confirmation Dialog Modal */}
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
                Cancel
              </button>
              <button 
                onClick={confirmDialog.action}
                className="flex-1 py-2 px-3 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-lg transition-colors cursor-pointer font-bold border-none"
              >
                {confirmDialog.type === 'suspend_student' ? 'Suspend' : confirmDialog.type === 'delete_student' || confirmDialog.type === 'delete_faculty' ? 'Delete' : 'Archive'}
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
