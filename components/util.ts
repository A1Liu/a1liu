import React, { useState, useRef, useCallback, useEffect } from "react";

export const timeout = (ms: number): Promise<void> =>
  new Promise((res) => setTimeout(res, ms));

