declare module 'node-clipboardy' {
  export function readSync(): string;
  export function writeSync(text: string): void;
  export default {
    readSync,
    writeSync
  };
}
