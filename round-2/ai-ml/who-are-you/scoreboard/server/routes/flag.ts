export default defineEventHandler((event) => {
  event.node.res.setHeader("Location", "https://youtu.be/dQw4w9WgXcQ");
  event.node.res.statusCode = 302;
  event.node.res.end();
});
