const fs = require('fs');
const file = 'src/routes/_app.forms.builder.$formId.tsx';
let content = fs.readFileSync(file, 'utf8');

// replace types in array
content = content.replace("{ id: 'multiple_choice', label: 'Multiple Choice', icon: Check },", "{ id: 'single_choice', label: 'Single Choice', icon: Check },");
content = content.replace("{ id: 'checkboxes', label: 'Checkboxes', icon: CheckSquare },", "{ id: 'multiple_choice', label: 'Multiple Choice (Checkboxes)', icon: CheckSquare },");
content = content.replace("{ id: 'linear_scale', label: 'Linear Scale', icon: ListOrdered },", "{ id: 'number_rating', label: 'Number Rating (Linear Scale)', icon: ListOrdered },");

// replace logic checks
// isChoice
content = content.replace("const isChoice = ['multiple_choice', 'checkboxes', 'dropdown'].includes(typeId);", "const isChoice = ['single_choice', 'multiple_choice', 'dropdown'].includes(typeId);");

// linear_scale validation
content = content.replace("validation_rules: typeId === 'linear_scale' ? { min: 1, max: 5 } : {},", "validation_rules: typeId === 'number_rating' ? { min: 1, max: 5 } : {},");

// multiple_choice / yes_no UI render
content = content.replace("{(q.type === 'multiple_choice' || q.type === 'yes_no') && (", "{(q.type === 'single_choice' || q.type === 'yes_no') && (");
// checkboxes UI render
content = content.replace("{q.type === 'checkboxes' && (", "{q.type === 'multiple_choice' && (");
// linear_scale UI render
content = content.replace("{q.type === 'linear_scale' && (", "{q.type === 'number_rating' && (");
content = content.replace("{q.type === 'linear_scale' && (", "{q.type === 'number_rating' && ("); // second instance

// options rendering in UI
content = content.replace("{(q.type === 'multiple_choice' || q.type === 'dropdown' || q.type === 'checkboxes' || q.type === 'yes_no') && (", "{(q.type === 'single_choice' || q.type === 'dropdown' || q.type === 'multiple_choice' || q.type === 'yes_no') && (");
content = content.replace("{(q.type === 'multiple_choice' || q.type === 'yes_no') ? 'rounded-full' : 'rounded'}", "{(q.type === 'single_choice' || q.type === 'yes_no') ? 'rounded-full' : 'rounded'}");

// settings panel linear scale
content = content.replace("{selectedQuestion.type === 'linear_scale' && (", "{selectedQuestion.type === 'number_rating' && (");
// options setting panel empty check
content = content.replace("!['short_text', 'long_text', 'number', 'roll_number', 'file_upload', 'linear_scale'].includes(selectedQuestion.type)", "!['short_text', 'long_text', 'number', 'roll_number', 'file_upload', 'number_rating'].includes(selectedQuestion.type)");

fs.writeFileSync(file, content);
console.log("Done");
