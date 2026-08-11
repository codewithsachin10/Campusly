const fs = require('fs');
const file = 'src/routes/form.$token.tsx';
let content = fs.readFileSync(file, 'utf8');

content = content.replace("q.type === 'multiple_choice' || q.type === 'dropdown'", "q.type === 'single_choice' || q.type === 'dropdown'");
content = content.replace("q.type === 'checkboxes'", "q.type === 'multiple_choice'");
content = content.replace("q.type === 'linear_scale'", "q.type === 'number_rating'");
content = content.replace("q.type === 'linear_scale'", "q.type === 'number_rating'"); // replace twice if needed

content = content.replace("if (q.type === 'checkboxes')", "if (q.type === 'multiple_choice')");
content = content.replace("if (q.type === 'multiple_choice' || q.type === 'dropdown' || q.type === 'yes_no')", "if (q.type === 'single_choice' || q.type === 'dropdown' || q.type === 'yes_no')");
content = content.replace("if (q.type === 'linear_scale' || q.type === 'number' || q.type === 'star_rating' || q.type === 'emoji_rating')", "if (q.type === 'number_rating' || q.type === 'number' || q.type === 'star_rating' || q.type === 'emoji_rating')");

fs.writeFileSync(file, content);
console.log("Done student");
