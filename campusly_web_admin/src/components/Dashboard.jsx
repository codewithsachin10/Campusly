import React, { useState, useEffect } from 'react';
import { signOut } from 'firebase/auth';
import { 
  collection, 
  doc, 
  setDoc, 
  getDocs, 
  addDoc, 
  deleteDoc, 
  updateDoc,
  onSnapshot 
} from 'firebase/firestore';
import { auth, db } from '../firebase';

export default function Dashboard({ user, onLogout }) {
  const [activeTab, setActiveTab] = useState('overview'); // overview, students, departments, faculty
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState('');
  
  // Real database states
  const [students, setStudents] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [sections, setSections] = useState([]);
  const [faculty, setFaculty] = useState([]);

  // Selection/Profile view states
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

  // State tree expand/collapse tracker for Dept Tree
  const [expandedNodes, setExpandedNodes] = useState({}); // e.g. { 'dept-cs': true, 'dept-cs-year-1': true }

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
    });

    // 3. Listen for Departments
    const unsubDepts = onSnapshot(collection(db, 'departments'), (snap) => {
      const list = [];
      snap.forEach(d => list.push({ id: d.id, ...d.data() }));
      setDepartments(list);
    });

    // 4. Listen for Sections
    const unsubSections = onSnapshot(collection(db, 'sections'), (snap) => {
      const list = [];
      snap.forEach(d => list.push({ id: d.id, ...d.data() }));
      setSections(list);
    });

    return () => {
      unsubStudents();
      unsubFaculty();
      unsubDepts();
      unsubSections();
    };
  }, []);

  // Prepopulate Firestore with default academic framework if collections are empty
  const handlePrepopulate = async () => {
    try {
      const deptSnap = await getDocs(collection(db, 'departments'));
      if (deptSnap.empty) {
        // Add Computer Science Dept
        const csDoc = await addDoc(collection(db, 'departments'), {
          name: 'Computer Science',
          shortCode: 'CS',
          studentCount: 4,
          sectionCount: 2,
          archived: false
        });
        // Add CS Sections
        await addDoc(collection(db, 'sections'), {
          name: 'Section A',
          departmentId: csDoc.id,
          year: '1st Year',
          studentCount: 2,
          archived: false
        });
        await addDoc(collection(db, 'sections'), {
          name: 'Section B',
          departmentId: csDoc.id,
          year: '1st Year',
          studentCount: 2,
          archived: false
        });

        // Add Electrical Engineering Dept
        const eeDoc = await addDoc(collection(db, 'departments'), {
          name: 'Electrical Engineering',
          shortCode: 'EE',
          studentCount: 0,
          sectionCount: 1,
          archived: false
        });
        await addDoc(collection(db, 'sections'), {
          name: 'Section A',
          departmentId: eeDoc.id,
          year: '1st Year',
          studentCount: 0,
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
        studentCount: 0,
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
    const deptId = sectionForm.departmentId || (departments[0]?.id || '');
    if (!sectionForm.name || !deptId) return;
    try {
      await addDoc(collection(db, 'sections'), {
        name: sectionForm.name,
        departmentId: deptId,
        year: sectionForm.year,
        studentCount: 0,
        archived: false
      });
      // Increment section count on department
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

  // Student State modifiers
  const handleSuspendStudent = async (studentId) => {
    try {
      const studentRef = doc(db, 'users', studentId);
      const student = students.find(s => s.id === studentId);
      const nextStatus = student?.status === 'Suspended' ? 'Active' : 'Suspended';
      await updateDoc(studentRef, { status: nextStatus });
      setConfirmDialog(null);
      setSelectedStudent(null);
      showToast(`Student account suspended successfully.`);
    } catch (err) {
      console.error(err);
      alert('Something went wrong. Please try again.');
    }
  };

  const handleDeleteStudent = async (studentId) => {
    try {
      await deleteDoc(doc(db, 'users', studentId));
      setConfirmDialog(null);
      setSelectedStudent(null);
      showToast('Student deleted successfully.');
    } catch (err) {
      console.error(err);
      alert('Something went wrong. Please try again.');
    }
  };

  // Faculty State modifiers
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

  // Department & Section Archival modifiers
  const handleArchiveDept = async (deptId) => {
    try {
      await updateDoc(doc(db, 'departments', deptId), { archived: true });
      setConfirmDialog(null);
      showToast('Academic structure archived successfully.');
    } catch (err) {
      console.error(err);
      alert('Something went wrong. Please try again.');
    }
  };

  const handleArchiveSection = async (sectionId) => {
    try {
      await updateDoc(doc(db, 'sections', sectionId), { archived: true });
      setConfirmDialog(null);
      showToast('Academic structure archived successfully.');
    } catch (err) {
      console.error(err);
      alert('Something went wrong. Please try again.');
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
                           f.email?.toLowerCase().includes(facultySearch.toLowerCase()));
    const matchesDept = facultyDeptFilter === 'All' || f.department === facultyDeptFilter;
    return matchesSearch && matchesDept;
  });

  return (
    <div className="min-h-screen bg-slate-50 flex">

      {/* LEFT SIDEBAR */}
      <aside className="w-64 bg-white border-r border-slate-200 flex flex-col justify-between fixed top-0 bottom-0 left-0 z-30">
        
        {/* Top Branding & Nav */}
        <div className="p-6 space-y-8">
          {/* Logo */}
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-slate-900 flex items-center justify-center text-white">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M22 10v6M2 10l10-5 10 5-10 5z"/>
                <path d="M6 12v5c0 2 2 3 6 3s6-1 6-3v-5"/>
              </svg>
            </div>
            <span className="text-lg font-bold tracking-tight text-slate-900">Campusly</span>
          </div>

          {/* Navigation Links */}
          <nav className="space-y-1.5">
            <button 
              onClick={() => { setActiveTab('overview'); setSelectedStudent(null); setSelectedFaculty(null); }}
              className={`w-full flex items-center gap-3 px-3 py-2.5 text-sm font-semibold rounded-lg transition-all ${
                activeTab === 'overview' 
                  ? 'bg-[#EFF6FF] text-secondary' 
                  : 'text-neutral hover:text-primary hover:bg-slate-50'
              }`}
            >
              <span className="material-symbols-outlined text-[20px]">dashboard</span>
              <span>Overview</span>
            </button>
            <button 
              onClick={() => { setActiveTab('students'); setSelectedStudent(null); setSelectedFaculty(null); }}
              className={`w-full flex items-center gap-3 px-3 py-2.5 text-sm font-semibold rounded-lg transition-all ${
                activeTab === 'students' 
                  ? 'bg-[#EFF6FF] text-secondary' 
                  : 'text-neutral hover:text-primary hover:bg-slate-50'
              }`}
            >
              <span className="material-symbols-outlined text-[20px]">person</span>
              <span>Students</span>
            </button>
            <button 
              onClick={() => { setActiveTab('departments'); setSelectedStudent(null); setSelectedFaculty(null); }}
              className={`w-full flex items-center gap-3 px-3 py-2.5 text-sm font-semibold rounded-lg transition-all ${
                activeTab === 'departments' 
                  ? 'bg-[#EFF6FF] text-secondary' 
                  : 'text-neutral hover:text-primary hover:bg-slate-50'
              }`}
            >
              <span className="material-symbols-outlined text-[20px]">account_balance</span>
              <span>Departments & Classes</span>
            </button>
            <button 
              onClick={() => { setActiveTab('faculty'); setSelectedStudent(null); setSelectedFaculty(null); }}
              className={`w-full flex items-center gap-3 px-3 py-2.5 text-sm font-semibold rounded-lg transition-all ${
                activeTab === 'faculty' 
                  ? 'bg-[#EFF6FF] text-secondary' 
                  : 'text-neutral hover:text-primary hover:bg-slate-50'
              }`}
            >
              <span className="material-symbols-outlined text-[20px]">group</span>
              <span>Faculty Directory</span>
            </button>
          </nav>
        </div>

        {/* Bottom Profile & Logout */}
        <div className="p-6 border-t border-slate-100 space-y-4">
          <div className="min-w-0">
            <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider leading-none mb-1">Administrator</p>
            <p className="text-sm font-bold text-slate-800 truncate" title={user?.email}>{user?.email || 'codewithsachin10@gmail.com'}</p>
          </div>
          <button 
            onClick={onLogout}
            className="w-full py-2 px-3 bg-slate-50 hover:bg-red-50 hover:text-red-600 border border-slate-200 hover:border-red-100 rounded-lg font-bold text-xs text-slate-700 transition-colors flex items-center justify-center gap-2 cursor-pointer"
          >
            <span className="material-symbols-outlined text-[16px]">logout</span>
            Logout
          </button>
        </div>

      </aside>

      {/* MAIN WORKSPACE CANVAS */}
      <main className="flex-1 ml-64 min-h-screen p-8 relative">

        {/* Loading skeleton loader state */}
        {loading ? (
          <div className="space-y-6">
            <div className="h-6 w-48 bg-slate-200 rounded animate-pulse"></div>
            <div className="h-4 w-64 bg-slate-200 rounded animate-pulse"></div>
            <div className="grid grid-cols-4 gap-6 pt-6">
              {[1, 2, 3, 4].map(n => (
                <div key={n} className="bg-white border border-slate-200 p-6 rounded-xl space-y-3 shadow-sm h-32 animate-pulse">
                  <div className="h-4 w-20 bg-slate-200 rounded"></div>
                  <div className="h-8 w-24 bg-slate-200 rounded"></div>
                </div>
              ))}
            </div>
            <div className="bg-white border border-slate-200 rounded-xl h-[400px] animate-pulse"></div>
          </div>
        ) : (
          <div className="max-w-[1200px] mx-auto space-y-8 animate-fade-in">
            
            {/* ============================== PAGE 3: OVERVIEW TAB ============================== */}
            {activeTab === 'overview' && (
              <div className="space-y-8">
                <div>
                  <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Overview</h1>
                  <p className="text-sm text-slate-500">Campusly system overview.</p>
                </div>

                {/* 4 Statistics grid */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
                  <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm">
                    <p className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Total Students</p>
                    <p className="text-3xl font-black text-slate-900">1,248</p>
                  </div>
                  <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm">
                    <p className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Active Students</p>
                    <p className="text-3xl font-black text-slate-900">1,186</p>
                  </div>
                  <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm">
                    <p className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Faculty</p>
                    <p className="text-3xl font-black text-slate-900">86</p>
                  </div>
                  <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm">
                    <p className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Departments</p>
                    <p className="text-3xl font-black text-slate-900">8</p>
                  </div>
                </div>

                {/* Current System Status Block */}
                <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm space-y-4">
                  <h3 className="text-base font-bold text-slate-900">Current System Status</h3>
                  <div className="divide-y divide-slate-100">
                    <div className="py-3 flex items-center justify-between">
                      <span className="text-sm font-semibold text-slate-700">Students</span>
                      <span className="px-2.5 py-0.5 bg-emerald-50 text-emerald-700 text-xs font-bold rounded-full border border-emerald-100 uppercase tracking-wide">Active</span>
                    </div>
                    <div className="py-3 flex items-center justify-between">
                      <span className="text-sm font-semibold text-slate-700">Faculty Directory</span>
                      <span className="px-2.5 py-0.5 bg-emerald-50 text-emerald-700 text-xs font-bold rounded-full border border-emerald-100 uppercase tracking-wide">Active</span>
                    </div>
                    <div className="py-3 flex items-center justify-between">
                      <span className="text-sm font-semibold text-slate-700">Academic Structure</span>
                      <span className="px-2.5 py-0.5 bg-blue-50 text-blue-700 text-xs font-bold rounded-full border border-blue-100 uppercase tracking-wide">Configured</span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* ============================== PAGE 4: STUDENTS TAB ============================== */}
            {activeTab === 'students' && (
              <div className="space-y-6">
                
                {/* Header row */}
                <div className="flex justify-between items-center">
                  <div>
                    <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Students</h1>
                    <p className="text-sm text-slate-500">Manage registered students.</p>
                  </div>
                  <button 
                    onClick={() => setModalType('add_student')}
                    className="py-2 px-4 bg-slate-900 hover:bg-slate-800 text-white font-semibold text-sm rounded-lg transition-colors flex items-center gap-1.5 shadow-sm cursor-pointer"
                  >
                    <span className="material-symbols-outlined text-[18px]">add</span>
                    Add Student
                  </button>
                </div>

                {/* SEARCH AND FILTERS */}
                <div className="bg-white border border-slate-200 rounded-xl p-4 shadow-sm flex flex-col md:flex-row gap-4">
                  <div className="flex-1 relative">
                    <span className="material-symbols-outlined absolute left-3 top-2.5 text-[20px] text-slate-400">search</span>
                    <input 
                      type="text" 
                      value={studentSearch}
                      onChange={(e) => setStudentSearch(e.target.value)}
                      placeholder="Search students..."
                      className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-lg text-sm text-slate-800 focus:outline-none focus:border-slate-400 placeholder:text-slate-400"
                    />
                  </div>
                  <div className="flex flex-wrap items-center gap-3">
                    <select 
                      value={studentDeptFilter} 
                      onChange={(e) => setStudentDeptFilter(e.target.value)}
                      className="border border-slate-200 rounded-lg p-2 text-xs font-semibold text-slate-700 bg-white"
                    >
                      <option value="All">All Departments</option>
                      <option value="Computer Science">Computer Science</option>
                      <option value="Electrical Engineering">Electrical Engineering</option>
                    </select>
                    <select 
                      value={studentYearFilter} 
                      onChange={(e) => setStudentYearFilter(e.target.value)}
                      className="border border-slate-200 rounded-lg p-2 text-xs font-semibold text-slate-700 bg-white"
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
                      className="border border-slate-200 rounded-lg p-2 text-xs font-semibold text-slate-700 bg-white"
                    >
                      <option value="All">All Sections</option>
                      <option value="Section A">Section A</option>
                      <option value="Section B">Section B</option>
                      <option value="Section C">Section C</option>
                    </select>
                    <select 
                      value={studentStatusFilter} 
                      onChange={(e) => setStudentStatusFilter(e.target.value)}
                      className="border border-slate-200 rounded-lg p-2 text-xs font-semibold text-slate-700 bg-white"
                    >
                      <option value="All">All Statuses</option>
                      <option value="Active">Active</option>
                      <option value="Suspended">Suspended</option>
                    </select>
                  </div>
                </div>

                {/* STUDENT TABLE */}
                <div className="bg-white border border-slate-200 rounded-xl overflow-hidden shadow-sm">
                  <div className="overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                      <thead>
                        <tr className="bg-slate-50 border-b border-slate-100 text-slate-400 font-bold text-xs uppercase tracking-wider">
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
                            <td className="px-6 py-4 font-bold text-slate-900">{s.name}</td>
                            <td className="px-6 py-4">{s.email}</td>
                            <td className="px-6 py-4">{s.department || 'Computer Science'}</td>
                            <td className="px-6 py-4">{s.year || '1st Year'}</td>
                            <td className="px-6 py-4">{s.section || 'Section A'}</td>
                            <td className="px-6 py-4">
                              <span className={`px-2 py-0.5 text-xs font-bold rounded-full border ${
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
                                className="p-1 hover:bg-slate-100 rounded transition-colors text-slate-400 hover:text-slate-600 cursor-pointer"
                              >
                                <span className="material-symbols-outlined text-[20px]">more_vert</span>
                              </button>
                              
                              {/* 3-dot dropdown menu */}
                              {activeDropdown === s.id && (
                                <div className="absolute right-6 top-12 w-36 bg-white border border-slate-200 rounded-lg shadow-lg py-1 z-20 text-left">
                                  <button 
                                    onClick={() => { setSelectedStudent(s); setActiveDropdown(null); }}
                                    className="w-full px-4 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50 flex items-center gap-2 cursor-pointer"
                                  >
                                    <span className="material-symbols-outlined text-[16px]">visibility</span>
                                    View Profile
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
                                    className="w-full px-4 py-2 text-xs font-semibold text-amber-700 hover:bg-amber-50 flex items-center gap-2 cursor-pointer"
                                  >
                                    <span className="material-symbols-outlined text-[16px]">pause_circle</span>
                                    {s.status === 'Suspended' ? 'Unsuspend' : 'Suspend'}
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
                                    className="w-full px-4 py-2 text-xs font-semibold text-red-700 hover:bg-red-50 flex items-center gap-2 border-t border-slate-100 cursor-pointer"
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

                {/* STUDENT PROFILE PANEL (SIDEBAR DRAWER) */}
                {selectedStudent && (
                  <div className="fixed inset-y-0 right-0 w-96 bg-white border-l border-slate-200 z-40 p-8 shadow-2xl flex flex-col justify-between animate-slide-in">
                    <div className="space-y-6">
                      <div className="flex justify-between items-center pb-4 border-b border-slate-100">
                        <h2 className="text-lg font-bold text-slate-900">Student Profile</h2>
                        <button 
                          onClick={() => setSelectedStudent(null)}
                          className="p-1 hover:bg-slate-100 rounded text-slate-400 hover:text-slate-600 cursor-pointer"
                        >
                          <span className="material-symbols-outlined">close</span>
                        </button>
                      </div>

                      {/* Student Info */}
                      <div className="space-y-4">
                        <div>
                          <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Student Information</h4>
                          <div className="bg-slate-50 rounded-lg p-4 space-y-2 border border-slate-100">
                            <p className="text-sm font-semibold text-slate-500">Name: <strong className="text-slate-800">{selectedStudent.name}</strong></p>
                            <p className="text-sm font-semibold text-slate-500">Email: <strong className="text-slate-800">{selectedStudent.email}</strong></p>
                          </div>
                        </div>

                        <div>
                          <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Academic Information</h4>
                          <div className="bg-slate-50 rounded-lg p-4 space-y-2 border border-slate-100">
                            <p className="text-sm font-semibold text-slate-500">Department: <strong className="text-slate-800">{selectedStudent.department || 'Computer Science'}</strong></p>
                            <p className="text-sm font-semibold text-slate-500">Year: <strong className="text-slate-800">{selectedStudent.year || '1st Year'}</strong></p>
                            <p className="text-sm font-semibold text-slate-500">Section: <strong className="text-slate-800">{selectedStudent.section || 'Section A'}</strong></p>
                          </div>
                        </div>

                        <div>
                          <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Account Information</h4>
                          <div className="bg-slate-50 rounded-lg p-4 space-y-2 border border-slate-100">
                            <p className="text-sm font-semibold text-slate-500">Joined Date: <strong className="text-slate-800">{selectedStudent.joinedDate || 'Jul 21, 2026'}</strong></p>
                            <p className="text-sm font-semibold text-slate-500">Last Active: <strong className="text-slate-800">{selectedStudent.lastActive || 'Never'}</strong></p>
                            <p className="text-sm font-semibold text-slate-500">App Version: <strong className="text-slate-800">{selectedStudent.appVersion || 'v1.0.0'}</strong></p>
                            <p className="text-sm font-semibold text-slate-500">Status: 
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

                    {/* Profile actions */}
                    <div className="grid grid-cols-2 gap-3 pt-6 border-t border-slate-100">
                      <button 
                        onClick={() => setConfirmDialog({
                          type: 'suspend_student',
                          message: 'Are you sure you want to suspend this student account?',
                          action: () => handleSuspendStudent(selectedStudent.id),
                          data: selectedStudent
                        })}
                        className="py-2.5 px-4 bg-slate-100 hover:bg-amber-50 text-slate-800 hover:text-amber-800 font-bold text-xs rounded-lg transition-colors border border-slate-200 hover:border-amber-100 cursor-pointer text-center"
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
                        className="py-2.5 px-4 bg-red-50 hover:bg-red-100 text-red-700 font-bold text-xs rounded-lg transition-colors border border-red-100 cursor-pointer text-center"
                      >
                        Delete Account
                      </button>
                    </div>

                  </div>
                )}

              </div>
            )}

            {/* ============================== PAGE 5: DEPARTMENTS & CLASSES TAB ============================== */}
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
                      className="py-2 px-4 bg-slate-900 hover:bg-slate-800 text-white font-semibold text-sm rounded-lg transition-colors flex items-center gap-1.5 shadow-sm cursor-pointer"
                    >
                      <span className="material-symbols-outlined text-[18px]">add</span>
                      Add Department
                    </button>
                  </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
                  
                  {/* Left Side: ACADEMIC STRUCTURE HIERARCHY TREE */}
                  <div className="lg:col-span-6 bg-white border border-slate-200 rounded-xl p-6 shadow-sm space-y-4">
                    <h3 className="text-base font-bold text-slate-900 border-b border-slate-100 pb-3">Academic Structure</h3>
                    
                    {departments.filter(d => !d.archived).length === 0 ? (
                      <p className="text-sm text-slate-400 font-semibold py-4 text-center">No departments created.</p>
                    ) : (
                      <div className="space-y-4">
                        {departments.filter(d => !d.archived).map((dept) => {
                          const isDeptExpanded = expandedNodes[`dept-${dept.id}`];
                          const deptSections = sections.filter(s => s.departmentId === dept.id && !s.archived);
                          
                          // Group sections by Year
                          const yearsMap = {};
                          deptSections.forEach(s => {
                            const yr = s.year || '1st Year';
                            if (!yearsMap[yr]) yearsMap[yr] = [];
                            yearsMap[yr].push(s);
                          });

                          return (
                            <div key={dept.id} className="border border-slate-100 rounded-lg overflow-hidden">
                              {/* Department node */}
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
                                  {dept.sectionCount || 0} Sects
                                </span>
                              </div>

                              {/* Years & Sections tree */}
                              {isDeptExpanded && (
                                <div className="p-3 pl-8 space-y-3 bg-white border-t border-slate-50">
                                  {Object.keys(yearsMap).length === 0 ? (
                                    <p className="text-xs text-slate-400 font-medium py-1">No sections available.</p>
                                  ) : (
                                    Object.keys(yearsMap).sort().map(year => {
                                      const isYearExpanded = expandedNodes[`dept-${dept.id}-year-${year}`];
                                      
                                      return (
                                        <div key={year} className="space-y-1.5">
                                          {/* Year Node */}
                                          <div 
                                            onClick={() => toggleNode(`dept-${dept.id}-year-${year}`)}
                                            className="flex items-center gap-2 py-1 text-xs font-bold text-slate-500 hover:text-slate-800 transition-colors cursor-pointer"
                                          >
                                            <span className="material-symbols-outlined text-[16px]">
                                              {isYearExpanded ? 'expand_more' : 'chevron_right'}
                                            </span>
                                            <span>{year}</span>
                                          </div>

                                          {/* Sections Node */}
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

                  {/* Right Side: DEPARTMENTS & SECTIONS DETAILS TABLES */}
                  <div className="lg:col-span-6 space-y-8">
                    
                    {/* Department info block list */}
                    <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm space-y-4">
                      <h3 className="text-base font-bold text-slate-900 border-b border-slate-100 pb-3">Department Information</h3>
                      <div className="space-y-3">
                        {departments.filter(d => !d.archived).map(d => (
                          <div key={d.id} className="flex items-center justify-between p-4 bg-slate-50/50 rounded-xl border border-slate-100">
                            <div>
                              <h4 className="text-sm font-bold text-slate-800">{d.name}</h4>
                              <p className="text-[11px] text-slate-500 font-semibold mt-1">
                                Code: <strong className="text-slate-700">{d.shortCode}</strong> &bull; Students: <strong className="text-slate-700">{students.filter(st => st.department === d.name).length}</strong> &bull; Sections: <strong className="text-slate-700">{sections.filter(s => s.departmentId === d.id && !s.archived).length}</strong>
                              </p>
                            </div>
                            <div className="flex gap-2">
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
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Section info block list */}
                    <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm space-y-4">
                      <h3 className="text-base font-bold text-slate-900 border-b border-slate-100 pb-3">Section Information</h3>
                      <div className="space-y-3">
                        {sections.filter(s => !s.archived).map(sec => {
                          const dept = departments.find(d => d.id === sec.departmentId);
                          return (
                            <div key={sec.id} className="flex items-center justify-between p-4 bg-slate-50/50 rounded-xl border border-slate-100">
                              <div>
                                <h4 className="text-sm font-bold text-slate-800">{sec.name}</h4>
                                <p className="text-[11px] text-slate-500 font-semibold mt-1">
                                  Dept: <strong className="text-slate-700">{dept?.name || 'Computer Science'}</strong> &bull; Year: <strong className="text-slate-700">{sec.year}</strong> &bull; Students: <strong className="text-slate-700">{students.filter(st => st.department === dept?.name && st.year === sec.year && st.section === sec.name).length}</strong>
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
                
                {/* Header row */}
                <div className="flex justify-between items-center">
                  <div>
                    <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Faculty Directory</h1>
                    <p className="text-sm text-slate-500">Manage faculty and cabin information.</p>
                  </div>
                  <button 
                    onClick={() => setModalType('add_faculty')}
                    className="py-2 px-4 bg-slate-900 hover:bg-slate-800 text-white font-semibold text-sm rounded-lg transition-colors flex items-center gap-1.5 shadow-sm cursor-pointer"
                  >
                    <span className="material-symbols-outlined text-[18px]">add</span>
                    Add Faculty
                  </button>
                </div>

                {/* SEARCH AND FILTER */}
                <div className="bg-white border border-slate-200 rounded-xl p-4 shadow-sm flex flex-col md:flex-row gap-4">
                  <div className="flex-1 relative">
                    <span className="material-symbols-outlined absolute left-3 top-2.5 text-[20px] text-slate-400">search</span>
                    <input 
                      type="text" 
                      value={facultySearch}
                      onChange={(e) => setFacultySearch(e.target.value)}
                      placeholder="Search faculty..."
                      className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-lg text-sm text-slate-800 focus:outline-none focus:border-slate-400 placeholder:text-slate-400"
                    />
                  </div>
                  <select 
                    value={facultyDeptFilter} 
                    onChange={(e) => setFacultyDeptFilter(e.target.value)}
                    className="border border-slate-200 rounded-lg p-2 text-xs font-semibold text-slate-700 bg-white"
                  >
                    <option value="All">All Departments</option>
                    <option value="Computer Science">Computer Science</option>
                    <option value="Electrical Engineering">Electrical Engineering</option>
                  </select>
                </div>

                {/* FACULTY TABLE */}
                <div className="bg-white border border-slate-200 rounded-xl overflow-hidden shadow-sm">
                  <div className="overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                      <thead>
                        <tr className="bg-slate-50 border-b border-slate-100 text-slate-400 font-bold text-xs uppercase tracking-wider">
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
                                className="px-2.5 py-1 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded text-xs font-bold text-slate-700 transition-colors cursor-pointer"
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
                                className="px-2.5 py-1 bg-red-50 hover:bg-red-100 border border-red-100 rounded text-xs font-bold text-red-700 transition-colors cursor-pointer"
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
                  <div className="fixed inset-y-0 right-0 w-96 bg-white border-l border-slate-200 z-40 p-8 shadow-2xl flex flex-col justify-between animate-slide-in">
                    <div className="space-y-6">
                      <div className="flex justify-between items-center pb-4 border-b border-slate-100">
                        <h2 className="text-lg font-bold text-slate-900">Faculty Details</h2>
                        <button 
                          onClick={() => setSelectedFaculty(null)}
                          className="p-1 hover:bg-slate-100 rounded text-slate-400 hover:text-slate-600 cursor-pointer"
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

                    <div className="pt-6 border-t border-slate-100">
                      <button 
                        onClick={() => {
                          setConfirmDialog({
                            type: 'delete_faculty',
                            message: 'Are you sure you want to delete this faculty profile?',
                            action: () => handleDeleteFaculty(selectedFaculty.id),
                            data: selectedFaculty
                          });
                        }}
                        className="w-full py-3 bg-red-50 hover:bg-red-100 text-red-700 font-bold text-xs rounded-lg border border-red-100 transition-colors cursor-pointer text-center"
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

      </main>

      {/* ========================================================================= */}
      {/* ============================== INTERACTIVE MODALS ======================== */}
      {/* ========================================================================= */}

      {/* 1. Add Student Modal */}
      {modalType === 'add_student' && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
          <div className="bg-white border border-slate-200 rounded-xl p-6 w-full max-w-[400px] shadow-xl space-y-6">
            <div className="flex justify-between items-center border-b border-slate-100 pb-3">
              <h3 className="text-base font-bold text-slate-900">Add Student</h3>
              <button onClick={() => setModalType(null)} className="text-slate-400 hover:text-slate-600 cursor-pointer">
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
                  required
                  className="w-full px-3.5 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:border-slate-400"
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Email</label>
                <input 
                  type="email" 
                  value={studentForm.email}
                  onChange={(e) => setStudentForm({ ...studentForm, email: e.target.value })}
                  placeholder="john.doe@college.edu"
                  required
                  className="w-full px-3.5 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:border-slate-400"
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Department</label>
                <select 
                  value={studentForm.department}
                  onChange={(e) => setStudentForm({ ...studentForm, department: e.target.value })}
                  className="w-full px-3.5 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none bg-white"
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
                    className="w-full px-3.5 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none bg-white"
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
                    className="w-full px-3.5 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none bg-white"
                  >
                    <option value="Section A">Section A</option>
                    <option value="Section B">Section B</option>
                    <option value="Section C">Section C</option>
                  </select>
                </div>
              </div>
              <div className="flex gap-3 pt-3">
                <button 
                  type="button" 
                  onClick={() => setModalType(null)} 
                  className="flex-1 py-2.5 border border-slate-200 rounded-lg text-sm font-semibold text-slate-700 hover:bg-slate-50 cursor-pointer"
                >
                  Cancel
                </button>
                <button 
                  type="submit" 
                  className="flex-1 py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-lg text-sm font-semibold cursor-pointer"
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
          <div className="bg-white border border-slate-200 rounded-xl p-6 w-full max-w-[400px] shadow-xl space-y-6">
            <div className="flex justify-between items-center border-b border-slate-100 pb-3">
              <h3 className="text-base font-bold text-slate-900">Add Department</h3>
              <button onClick={() => setModalType(null)} className="text-slate-400 hover:text-slate-600 cursor-pointer">
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
                  required
                  className="w-full px-3.5 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:border-slate-400"
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Short Code</label>
                <input 
                  type="text" 
                  value={deptForm.shortCode}
                  onChange={(e) => setDeptForm({ ...deptForm, shortCode: e.target.value })}
                  placeholder="e.g. ME"
                  required
                  className="w-full px-3.5 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:border-slate-400"
                />
              </div>
              <div className="flex gap-3 pt-3">
                <button 
                  type="button" 
                  onClick={() => setModalType(null)} 
                  className="flex-1 py-2.5 border border-slate-200 rounded-lg text-sm font-semibold text-slate-700 hover:bg-slate-50 cursor-pointer"
                >
                  Cancel
                </button>
                <button 
                  type="submit" 
                  className="flex-1 py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-lg text-sm font-semibold cursor-pointer"
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
          <div className="bg-white border border-slate-200 rounded-xl p-6 w-full max-w-[400px] shadow-xl space-y-6">
            <div className="flex justify-between items-center border-b border-slate-100 pb-3">
              <h3 className="text-base font-bold text-slate-900">Add Section</h3>
              <button onClick={() => setModalType(null)} className="text-slate-400 hover:text-slate-600 cursor-pointer">
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>
            <form onSubmit={handleAddSection} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Department</label>
                <select 
                  value={sectionForm.departmentId}
                  onChange={(e) => setSectionForm({ ...sectionForm, departmentId: e.target.value })}
                  className="w-full px-3.5 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none bg-white"
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
                  className="w-full px-3.5 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none bg-white"
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
                  required
                  className="w-full px-3.5 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:border-slate-400"
                />
              </div>
              <div className="flex gap-3 pt-3">
                <button 
                  type="button" 
                  onClick={() => setModalType(null)} 
                  className="flex-1 py-2.5 border border-slate-200 rounded-lg text-sm font-semibold text-slate-700 hover:bg-slate-50 cursor-pointer"
                >
                  Cancel
                </button>
                <button 
                  type="submit" 
                  className="flex-1 py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-lg text-sm font-semibold cursor-pointer"
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
          <div className="bg-white border border-slate-200 rounded-xl p-6 w-full max-w-[400px] shadow-xl space-y-6">
            <div className="flex justify-between items-center border-b border-slate-100 pb-3">
              <h3 className="text-base font-bold text-slate-900">Add Faculty</h3>
              <button onClick={() => setModalType(null)} className="text-slate-400 hover:text-slate-600 cursor-pointer">
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
                  placeholder="e.g. Dr. Amit Sharma"
                  required
                  className="w-full px-3.5 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:border-slate-400"
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Email</label>
                <input 
                  type="email" 
                  value={facultyForm.email}
                  onChange={(e) => setFacultyForm({ ...facultyForm, email: e.target.value })}
                  placeholder="amit.sharma@college.edu"
                  required
                  className="w-full px-3.5 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:border-slate-400"
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Department</label>
                <select 
                  value={facultyForm.department}
                  onChange={(e) => setFacultyForm({ ...facultyForm, department: e.target.value })}
                  className="w-full px-3.5 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none bg-white"
                >
                  <option value="Computer Science">Computer Science</option>
                  <option value="Electrical Engineering">Electrical Engineering</option>
                </select>
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase">Cabin Location</label>
                <input 
                  type="text" 
                  value={facultyForm.cabin}
                  onChange={(e) => setFacultyForm({ ...facultyForm, cabin: e.target.value })}
                  placeholder="e.g. Cabin 302"
                  required
                  className="w-full px-3.5 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:border-slate-400"
                />
              </div>
              <div className="flex gap-3 pt-3">
                <button 
                  type="button" 
                  onClick={() => setModalType(null)} 
                  className="flex-1 py-2.5 border border-slate-200 rounded-lg text-sm font-semibold text-slate-700 hover:bg-slate-50 cursor-pointer"
                >
                  Cancel
                </button>
                <button 
                  type="submit" 
                  className="flex-1 py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-lg text-sm font-semibold cursor-pointer"
                >
                  Add Faculty
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* ============================== CONFIRMATION DIALOGS ====================== */}
      {/* ========================================================================= */}
      {confirmDialog && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
          <div className="bg-white border border-slate-200 rounded-xl p-6 w-full max-w-[360px] shadow-xl text-center space-y-6">
            <div className="w-12 h-12 rounded-full bg-red-50 text-red-600 flex items-center justify-center mx-auto border border-red-100">
              <span className="material-symbols-outlined text-[24px]">warning</span>
            </div>
            
            <div className="space-y-2">
              <h3 className="text-base font-bold text-slate-900">Confirm Action</h3>
              <p className="text-sm text-slate-500 leading-relaxed">{confirmDialog.message}</p>
            </div>

            <div className="flex gap-3">
              <button 
                onClick={() => setConfirmDialog(null)}
                className="flex-1 py-2 border border-slate-200 rounded-lg text-xs font-bold text-slate-700 hover:bg-slate-50 cursor-pointer"
              >
                Cancel
              </button>
              <button 
                onClick={confirmDialog.action}
                className="flex-1 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg text-xs font-bold cursor-pointer"
              >
                {confirmDialog.type.includes('suspend') ? 'Suspend' : confirmDialog.type.includes('archive') ? 'Archive' : 'Delete'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* ============================== ALERT TOASTS ============================== */}
      {/* ========================================================================= */}
      {toast && (
        <div className="fixed bottom-6 right-6 bg-slate-900 text-white px-4 py-3 rounded-lg shadow-lg flex items-center gap-2 z-50 text-xs font-semibold border border-slate-800 animate-slide-in">
          <span className="material-symbols-outlined text-[16px] text-emerald-400">check_circle</span>
          <span>{toast}</span>
        </div>
      )}

    </div>
  );
}
