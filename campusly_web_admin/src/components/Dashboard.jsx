import React, { useState, useEffect } from 'react';
import { signOut } from 'firebase/auth';
import { 
  collection, 
  doc, 
  getDoc, 
  setDoc, 
  getDocs, 
  addDoc, 
  deleteDoc, 
  onSnapshot,
  query,
  limit
} from 'firebase/firestore';
import { auth, db } from '../firebase';
import { 
  Cpu, 
  Megaphone, 
  Users, 
  LayoutDashboard, 
  LogOut, 
  Save, 
  Plus, 
  Trash2, 
  CheckCircle,
  FileSpreadsheet,
  AlertTriangle
} from 'lucide-react';

export default function Dashboard({ user, onLogout }) {
  const [activeTab, setActiveTab] = useState('overview');
  const [loading, setLoading] = useState(false);
  const [statusMsg, setStatusMsg] = useState({ type: '', text: '' });

  // Dashboard Stats
  const [stats, setStats] = useState({
    usersCount: 0,
    noticesCount: 0,
    facultyCount: 0
  });

  // 1. In-App Updates State
  const [updatesConfig, setUpdatesConfig] = useState({
    latestVersionCode: 1,
    latestVersionName: '1.0.0',
    critical: false,
    apkUrl: '',
    releaseNotes: ''
  });

  // 2. Notices/Announcements State
  const [notices, setNotices] = useState([]);
  const [newNotice, setNewNotice] = useState({
    title: '',
    message: '',
    highPriority: false
  });

  // 3. Faculty Cabin State
  const [faculties, setFaculties] = useState([]);
  const [newFaculty, setNewFaculty] = useState({
    name: '',
    email: '',
    department: '',
    cabin: ''
  });

  // Status message timeout helper
  const showStatus = (type, text) => {
    setStatusMsg({ type, text });
    setTimeout(() => setStatusMsg({ type: '', text: '' }), 4000);
  };

  // Fetch stats and real-time listeners
  useEffect(() => {
    // 1. Listen for Updates config
    const unsubUpdates = onSnapshot(doc(db, 'app_config', 'update'), (docSnap) => {
      if (docSnap.exists()) {
        setUpdatesConfig(docSnap.data());
      }
    });

    // 2. Listen for Live announcements
    const unsubNotices = onSnapshot(collection(db, 'announcements'), (snap) => {
      const list = [];
      snap.forEach(d => list.push({ id: d.id, ...d.data() }));
      // Sort by timestamp desc
      list.sort((a, b) => (b.timestamp?.seconds || 0) - (a.timestamp?.seconds || 0));
      setNotices(list);
      setStats(prev => ({ ...prev, noticesCount: list.length }));
    });

    // 3. Listen for Faculty directory
    const unsubFaculty = onSnapshot(collection(db, 'faculties'), (snap) => {
      const list = [];
      snap.forEach(d => list.push({ id: d.id, ...d.data() }));
      list.sort((a, b) => a.name.localeCompare(b.name));
      setFaculties(list);
      setStats(prev => ({ ...prev, facultyCount: list.length }));
    });

    // 4. Get total registered users (one-time fetch for stats)
    getDocs(collection(db, 'users')).then(snap => {
      setStats(prev => ({ ...prev, usersCount: snap.size }));
    }).catch(err => console.error("Error reading users count:", err));

    return () => {
      unsubUpdates();
      unsubNotices();
      unsubFaculty();
    };
  }, []);

  const handleLogout = async () => {
    await signOut(auth);
    onLogout();
  };

  // --- Save In-App Update Config ---
  const saveUpdatesConfig = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await setDoc(doc(db, 'app_config', 'update'), {
        ...updatesConfig,
        latestVersionCode: parseInt(updatesConfig.latestVersionCode) || 1,
        updatedAt: new Date()
      }, { merge: true });
      showStatus('success', 'In-App Update configuration saved successfully!');
    } catch (err) {
      console.error(err);
      showStatus('error', 'Failed to save update configuration.');
    } finally {
      setLoading(false);
    }
  };

  // --- Add Live Announcement ---
  const postNotice = async (e) => {
    e.preventDefault();
    if (!newNotice.title || !newNotice.message) return;
    setLoading(true);
    try {
      await addDoc(collection(db, 'announcements'), {
        title: newNotice.title,
        message: newNotice.message,
        highPriority: newNotice.highPriority,
        author: 'Administrator',
        timestamp: new Date()
      });
      setNewNotice({ title: '', message: '', highPriority: false });
      showStatus('success', 'Announcement published in real-time!');
    } catch (err) {
      console.error(err);
      showStatus('error', 'Failed to publish announcement.');
    } finally {
      setLoading(false);
    }
  };

  // --- Delete Notice ---
  const deleteNotice = async (id) => {
    if (!window.confirm('Delete this notice? It will instantly disappear from all student devices.')) return;
    try {
      await deleteDoc(doc(db, 'announcements', id));
      showStatus('success', 'Notice deleted.');
    } catch (err) {
      console.error(err);
      showStatus('error', 'Error deleting notice.');
    }
  };

  // --- Add Faculty Member ---
  const addFaculty = async (e) => {
    e.preventDefault();
    if (!newFaculty.name || !newFaculty.cabin) return;
    setLoading(true);
    try {
      await addDoc(collection(db, 'faculties'), {
        name: newFaculty.name,
        email: newFaculty.email || 'N/A',
        department: newFaculty.department || 'N/A',
        cabin: newFaculty.cabin
      });
      setNewFaculty({ name: '', email: '', department: '', cabin: '' });
      showStatus('success', 'Faculty member added to directory!');
    } catch (err) {
      console.error(err);
      showStatus('error', 'Failed to add faculty member.');
    } finally {
      setLoading(false);
    }
  };

  // --- Delete Faculty ---
  const deleteFaculty = async (id) => {
    if (!window.confirm('Delete this faculty member from directory?')) return;
    try {
      await deleteDoc(doc(db, 'faculties', id));
      showStatus('success', 'Faculty member removed.');
    } catch (err) {
      console.error(err);
      showStatus('error', 'Error removing faculty member.');
    }
  };

  return (
    <div className="app-container">
      {/* Sidebar navigation */}
      <div className="sidebar">
        <div className="logo-section">
          <div className="logo-text">CAMPUSLY</div>
        </div>
        <div className="nav-links">
          <div 
            className={`nav-item ${activeTab === 'overview' ? 'active' : ''}`}
            onClick={() => setActiveTab('overview')}
          >
            <LayoutDashboard size={18} />
            <span>Overview</span>
          </div>
          <div 
            className={`nav-item ${activeTab === 'updates' ? 'active' : ''}`}
            onClick={() => setActiveTab('updates')}
          >
            <Cpu size={18} />
            <span>In-App Updates</span>
          </div>
          <div 
            className={`nav-item ${activeTab === 'notices' ? 'active' : ''}`}
            onClick={() => setActiveTab('notices')}
          >
            <Megaphone size={18} />
            <span>Notice Board</span>
          </div>
          <div 
            className={`nav-item ${activeTab === 'faculty' ? 'active' : ''}`}
            onClick={() => setActiveTab('faculty')}
          >
            <Users size={18} />
            <span>Faculty Directory</span>
          </div>

          <div className="nav-item logout-btn" onClick={handleLogout}>
            <LogOut size={18} />
            <span>Logout</span>
          </div>
        </div>
      </div>

      {/* Main content body */}
      <div className="main-content">
        {statusMsg.text && (
          <div 
            className="glass-panel" 
            style={{
              position: 'fixed',
              top: '24px',
              right: '24px',
              padding: '16px 24px',
              zIndex: 9999,
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              borderLeft: `4px solid ${statusMsg.type === 'success' ? 'var(--success)' : 'var(--error)'}`
            }}
          >
            <CheckCircle size={20} color={statusMsg.type === 'success' ? 'var(--success)' : 'var(--error)'} />
            <span style={{ fontWeight: 600 }}>{statusMsg.text}</span>
          </div>
        )}

        {/* --- OVERVIEW TAB --- */}
        {activeTab === 'overview' && (
          <div>
            <h1>Overview</h1>
            <p className="subtitle">Real-time metrics and system health indicators</p>

            <div className="grid-container">
              <div className="glass-panel stat-card">
                <div className="stat-icon-container">
                  <Users size={24} color="var(--primary-accent)" />
                </div>
                <div className="stat-details">
                  <h3>Total Enrolled Students</h3>
                  <p>{stats.usersCount}</p>
                </div>
              </div>

              <div className="glass-panel stat-card">
                <div className="stat-icon-container">
                  <Megaphone size={24} color="var(--primary-accent)" />
                </div>
                <div className="stat-details">
                  <h3>Active Notices</h3>
                  <p>{stats.noticesCount}</p>
                </div>
              </div>

              <div className="glass-panel stat-card">
                <div className="stat-icon-container">
                  <Users size={24} color="var(--primary-accent)" />
                </div>
                <div className="stat-details">
                  <h3>Faculty Members</h3>
                  <p>{stats.facultyCount}</p>
                </div>
              </div>
            </div>

            <div className="glass-panel form-section" style={{ maxWidth: '100%' }}>
              <h2 className="form-title">
                <Cpu size={20} color="var(--primary-accent)" />
                <span>Active Update Distribution Configuration</span>
              </h2>
              <table className="item-table">
                <tbody>
                  <tr>
                    <td><strong>Latest Version Name</strong></td>
                    <td>v{updatesConfig.latestVersionName} (Code: {updatesConfig.latestVersionCode})</td>
                  </tr>
                  <tr>
                    <td><strong>Release Priority</strong></td>
                    <td>
                      <span style={{ 
                        color: updatesConfig.critical ? 'var(--error)' : 'var(--success)',
                        fontWeight: 'bold' 
                      }}>
                        {updatesConfig.critical ? '🚨 Mandatory Blocking Release' : '✅ Flexible Optional Release'}
                      </span>
                    </td>
                  </tr>
                  <tr>
                    <td><strong>APK Distribution Path</strong></td>
                    <td><a href={updatesConfig.apkUrl} target="_blank" rel="noreferrer" style={{ color: 'var(--primary-accent)' }}>{updatesConfig.apkUrl}</a></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* --- IN-APP UPDATES TAB --- */}
        {activeTab === 'updates' && (
          <div>
            <h1>In-App Updates</h1>
            <p className="subtitle">Configure and roll out free custom version checks instantly</p>

            <form onSubmit={saveUpdatesConfig} className="glass-panel form-section">
              <h2 className="form-title">
                <Cpu size={20} />
                <span>Configure Version Parameters</span>
              </h2>

              <div className="form-group" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                <div>
                  <label htmlFor="versionCode">Latest Version Code (Build Number)</label>
                  <input
                    type="number"
                    id="versionCode"
                    value={updatesConfig.latestVersionCode}
                    onChange={(e) => setUpdatesConfig({ ...updatesConfig, latestVersionCode: e.target.value })}
                    required
                  />
                </div>
                <div>
                  <label htmlFor="versionName">Latest Version Name (e.g. 1.0.1)</label>
                  <input
                    type="text"
                    id="versionName"
                    value={updatesConfig.latestVersionName}
                    onChange={(e) => setUpdatesConfig({ ...updatesConfig, latestVersionName: e.target.value })}
                    required
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="checkbox-group">
                  <input
                    type="checkbox"
                    checked={updatesConfig.critical}
                    onChange={(e) => setUpdatesConfig({ ...updatesConfig, critical: e.target.checked })}
                  />
                  <span>🚨 Mark update as critical (forces a blocking full-screen update prompt)</span>
                </label>
              </div>

              <div className="form-group">
                <label htmlFor="apkUrl">APK Download URL</label>
                <input
                  type="url"
                  id="apkUrl"
                  placeholder="https://github.com/yourname/yourrepo/releases/download/v1.0.1/app-release.apk"
                  value={updatesConfig.apkUrl}
                  onChange={(e) => setUpdatesConfig({ ...updatesConfig, apkUrl: e.target.value })}
                  required
                />
              </div>

              <div className="form-group">
                <label htmlFor="releaseNotes">Release Notes / What's New</label>
                <textarea
                  id="releaseNotes"
                  rows={4}
                  placeholder="Minor UI improvements and camera scanning fixes..."
                  value={updatesConfig.releaseNotes}
                  onChange={(e) => setUpdatesConfig({ ...updatesConfig, releaseNotes: e.target.value })}
                />
              </div>

              <button type="submit" className="btn btn-primary" disabled={loading}>
                <Save size={18} />
                {loading ? 'Saving Parameters...' : 'Deploy Update Settings'}
              </button>
            </form>
          </div>
        )}

        {/* --- NOTICE BOARD TAB --- */}
        {activeTab === 'notices' && (
          <div>
            <h1>Notice Board Announcements</h1>
            <p className="subtitle">Publish notices that sync instantly with student dashboards</p>

            <form onSubmit={postNotice} className="glass-panel form-section">
              <h2 className="form-title">
                <Megaphone size={20} />
                <span>Post Live Announcement</span>
              </h2>

              <div className="form-group">
                <label htmlFor="noticeTitle">Notice Title</label>
                <input
                  type="text"
                  id="noticeTitle"
                  placeholder="e.g. Schedule Change / Event Registration"
                  value={newNotice.title}
                  onChange={(e) => setNewNotice({ ...newNotice, title: e.target.value })}
                  required
                />
              </div>

              <div className="form-group">
                <label htmlFor="noticeMessage">Notice Message</label>
                <textarea
                  id="noticeMessage"
                  rows={3}
                  placeholder="Type the message body details here..."
                  value={newNotice.message}
                  onChange={(e) => setNewNotice({ ...newNotice, message: e.target.value })}
                  required
                />
              </div>

              <div className="form-group">
                <label className="checkbox-group">
                  <input
                    type="checkbox"
                    checked={newNotice.highPriority}
                    onChange={(e) => setNewNotice({ ...newNotice, highPriority: e.target.checked })}
                  />
                  <span>⚠️ Flag as High Priority Alert (shows highlighted alert styling)</span>
                </label>
              </div>

              <button type="submit" className="btn btn-primary" disabled={loading}>
                <Plus size={18} />
                Publish to Notice Board
              </button>
            </form>

            <h2 style={{ marginTop: '40px', fontSize: '22px' }}>Live Notice History ({notices.length})</h2>
            <div className="notices-list">
              {notices.map((n) => (
                <div key={n.id} className="glass-panel notice-item">
                  <span className={`notice-badge ${n.highPriority ? 'critical' : 'info'}`}>
                    {n.highPriority ? 'High Alert' : 'Regular'}
                  </span>
                  <h3 style={{ margin: '0 0 8px 0', fontSize: '18px', paddingRight: '120px' }}>{n.title}</h3>
                  <p style={{ color: 'var(--text-secondary)', margin: '0 0 16px 0', fontSize: '15px' }}>{n.message}</p>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                      Published on: {n.timestamp?.seconds ? new Date(n.timestamp.seconds * 1000).toLocaleString() : 'Just now'}
                    </span>
                    <button 
                      className="btn" 
                      style={{ padding: '6px 12px', background: 'rgba(239,68,68,0.1)', color: '#f87171' }}
                      onClick={() => deleteNotice(n.id)}
                    >
                      <Trash2 size={14} />
                      Remove Notice
                    </button>
                  </div>
                </div>
              ))}
              {notices.length === 0 && (
                <p style={{ color: 'var(--text-secondary)' }}>No live notices currently published.</p>
              )}
            </div>
          </div>
        )}

        {/* --- FACULTY TAB --- */}
        {activeTab === 'faculty' && (
          <div>
            <h1>Faculty Directory</h1>
            <p className="subtitle">Manage professors, contact directories, and cabinet coordinates</p>

            <form onSubmit={addFaculty} className="glass-panel form-section">
              <h2 className="form-title">
                <Users size={20} />
                <span>Add Faculty Member</span>
              </h2>

              <div className="form-group" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                <div>
                  <label htmlFor="facName">Professor Name</label>
                  <input
                    type="text"
                    id="facName"
                    placeholder="e.g. Dr. Ramesh Kumar"
                    value={newFaculty.name}
                    onChange={(e) => setNewFaculty({ ...newFaculty, name: e.target.value })}
                    required
                  />
                </div>
                <div>
                  <label htmlFor="facCabin">Office Cabin / Location</label>
                  <input
                    type="text"
                    id="facCabin"
                    placeholder="e.g. CS Block Room 402"
                    value={newFaculty.cabin}
                    onChange={(e) => setNewFaculty({ ...newFaculty, cabin: e.target.value })}
                    required
                  />
                </div>
              </div>

              <div className="form-group" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                <div>
                  <label htmlFor="facEmail">Email Address</label>
                  <input
                    type="email"
                    id="facEmail"
                    placeholder="ramesh.k@college.edu"
                    value={newFaculty.email}
                    onChange={(e) => setNewFaculty({ ...newFaculty, email: e.target.value })}
                  />
                </div>
                <div>
                  <label htmlFor="facDept">Department</label>
                  <input
                    type="text"
                    id="facDept"
                    placeholder="e.g. Computer Science / ECE"
                    value={newFaculty.department}
                    onChange={(e) => setNewFaculty({ ...newFaculty, department: e.target.value })}
                  />
                </div>
              </div>

              <button type="submit" className="btn btn-primary" disabled={loading}>
                <Plus size={18} />
                Add to Directory
              </button>
            </form>

            <div className="glass-panel" style={{ marginTop: '40px', padding: '24px', overflowX: 'auto' }}>
              <h2 style={{ margin: '0 0 16px 0', fontSize: '20px' }}>Faculty Directory Listing</h2>
              <table className="item-table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Cabin Location</th>
                    <th>Email Address</th>
                    <th>Department</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {faculties.map((f) => (
                    <tr key={f.id}>
                      <td><strong>{f.name}</strong></td>
                      <td><span style={{ color: 'var(--success)', fontWeight: 600 }}>{f.cabin}</span></td>
                      <td>{f.email}</td>
                      <td>{f.department}</td>
                      <td>
                        <Trash2 
                          className="action-icon" 
                          size={18} 
                          onClick={() => deleteFaculty(f.id)} 
                        />
                      </td>
                    </tr>
                  ))}
                  {faculties.length === 0 && (
                    <tr>
                      <td colSpan={5} style={{ textAlign: 'center', color: 'var(--text-secondary)' }}>
                        No faculty members currently listed.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
